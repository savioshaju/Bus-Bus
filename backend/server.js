require("dotenv").config();
const express = require("express");
const bcrypt = require("bcryptjs");
const jwt = require("jsonwebtoken");
const cors = require("cors");
const { createClient } = require('@supabase/supabase-js');

const app = express();
app.use(express.json());
app.use(cors());

// Initialize Supabase Client
const supabase = createClient(process.env.SUPABASE_URL, process.env.SUPABASE_ANON_KEY);

// Middleware to verify JWT Token
const verifyToken = (req, res, next) => {
  const token = req.headers["authorization"];
  if (!token) return res.status(403).json({ message: "Access denied" });

  jwt.verify(token.split(" ")[1], process.env.JWT_SECRET, (err, decoded) => {
    if (err) return res.status(401).json({ message: "Invalid token" });
    req.user = decoded;
    next();
  });
};

// User Login
app.post("/login", async (req, res) => {
  const { username, password } = req.body;

  if (!username || !password) {
    return res.status(400).json({ message: "Username and password are required" });
  }

  // Fetch user from Supabase
  const { data, error } = await supabase
    .from('users')
    .select('id, role, status, password')
    .eq('username', username)
    .single();

  if (error) {
    console.error("Error fetching user:", error);
    return res.status(500).json({ message: "Internal server error" });
  }

  if (!data) {
    return res.status(401).json({ message: "Invalid username or password" });
  }

  const user = data;
  const passwordMatch = await bcrypt.compare(password, user.password);

  if (!passwordMatch) {
    return res.status(401).json({ message: "Invalid username or password" });
  }

  if (user.role === "Transit Provider" && user.status === "Pending") {
    return res.status(403).json({ message: "Approval pending by admin" });
  }

  const token = jwt.sign({ id: user.id, role: user.role }, process.env.JWT_SECRET, { expiresIn: "1h" });
  const refreshToken = jwt.sign({ id: user.id }, process.env.JWT_SECRET, { expiresIn: "7d" });

  res.json({ token, refreshToken, role: user.role, status: user.status });
});

// Fetch Pending Transit Providers (Admin Only)
app.get("/admin/pending-providers", verifyToken, async (req, res) => {
  if (req.user.role.toLowerCase() !== "admin") {
    return res.status(403).json({ message: "Unauthorized access" });
  }

  // Fetch pending transit providers from Supabase
  const { data, error } = await supabase
    .from('users')
    .select('id, first_name, middle_name, last_name, email, phone_number, dob, address')
    .eq('role', 'Transit Provider')
    .eq('status', 'Pending');

  if (error) {
    console.error("Error fetching providers:", error);
    return res.status(500).json({ message: "Internal server error", error: error.message });
  }

  res.json(data);
});

// Approve or Reject a Provider (Admin Only)
app.post("/admin/approve-provider", verifyToken, async (req, res) => {
  if (req.user.role.toLowerCase() !== "admin") {
    return res.status(403).json({ message: "Unauthorized access" });
  }

  const { userId, status } = req.body;

  if (!["Approved", "Rejected"].includes(status)) {
    return res.status(400).json({ message: "Invalid status. Use 'Approved' or 'Rejected'." });
  }

  // Update status of the provider in Supabase
  const { data, error } = await supabase
    .from('users')
    .update({ status })
    .eq('id', userId);

  if (error) {
    console.error("Error updating status:", error);
    return res.status(500).json({ message: "Internal server error", error: error.message });
  }

  if (data.length === 0) {
    return res.status(404).json({ message: "User not found or already updated" });
  }

  res.json({ message: `Provider ${status.toLowerCase()} successfully` });
});
app.post("/signup", async (req, res) => {
  const { first_name, middle_name, last_name, username, email, phone_number, password, dob, address, role } = req.body;

  // Validation (you can extend this as needed)
  if (!first_name || !last_name || !username || !email || !password) {
    return res.status(400).json({ message: "Please provide all required fields" });
  }

  // Check if username already exists
  const { data: existingUserByUsername, error: errorByUsername } = await supabase
    .from('users')
    .select('id')
    .eq('username', username)
    .single();

  if (existingUserByUsername) {
    return res.status(400).json({ message: "Username already exists" });
  }

  // Check if email already exists
  const { data: existingUserByEmail, error: errorByEmail } = await supabase
    .from('users')
    .select('id')
    .eq('email', email)
    .single();

  if (existingUserByEmail) {
    return res.status(400).json({ message: "Email already in use" });
  }
  const { data: existingPhoneNumber, error: phoneError } = await supabase
    .from('users')
    .select('id')
    .eq('phone_number', phone_number)
    .single();  // We use .single() since we expect at most one result


  if (existingPhoneNumber) {
    return res.status(400).json({ message: "Phone number already in use" });
  }

  // Hash password
  const hashedPassword = await bcrypt.hash(password, 10);

  // Insert user data into Supabase (no need to provide 'id' as it's auto-incremented)
  const { data: newUser, error: insertError } = await supabase
    .from('users')
    .insert([
      {
        first_name,
        middle_name,
        last_name,
        username,
        email,
        phone_number,
        password: hashedPassword,
        dob,
        address,
        role,
        status: 'Pending', // default to pending status
      }
    ])
    .single();

  if (insertError) {
    console.error("Error inserting user:", insertError);
    return res.status(500).json({ message: "Error registering user" });
  }

  res.status(200).json({ message: "User registered successfully", user: newUser });
});

// Start Server
app.listen(5000, () => {
  console.log("Server running on port 5000");
});
