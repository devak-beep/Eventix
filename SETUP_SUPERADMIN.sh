#!/bin/bash
# SETUP_SUPERADMIN.sh - Create initial SuperAdmin account
# Usage: bash SETUP_SUPERADMIN.sh
# This script creates the first superAdmin account required for admin hierarchy

echo "================================"
echo "Eventix SuperAdmin Setup Script"
echo "================================"
echo ""

# Check if MongoDB is accessible
echo "⏳ Checking MongoDB connection..."
mongo --version > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "❌ MongoDB CLI not found. Please install MongoDB first."
    exit 1
fi

echo "✓ MongoDB found"
echo ""

# Collect SuperAdmin details
echo "Enter SuperAdmin details:"
echo "================================"
read -p "Full Name: " ADMIN_NAME
read -p "Email: " ADMIN_EMAIL
read -s -p "Password (min 6 chars, 1 number, 1 special char): " ADMIN_PASSWORD
echo ""

# Validate inputs
if [ -z "$ADMIN_NAME" ] || [ -z "$ADMIN_EMAIL" ] || [ -z "$ADMIN_PASSWORD" ]; then
    echo "❌ All fields are required!"
    exit 1
fi

if [ ${#ADMIN_PASSWORD} -lt 6 ]; then
    echo "❌ Password must be at least 6 characters!"
    exit 1
fi

echo ""
echo "================================"
echo "SuperAdmin to be created:"
echo "Name: $ADMIN_NAME"
echo "Email: $ADMIN_EMAIL"
echo "================================"
echo ""
read -p "Confirm? (y/n) " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Cancelled."
    exit 1
fi

echo ""
echo "⏳ Creating SuperAdmin account..."
echo ""

# Run Node script to create superAdmin
node << 'EOF'
const mongoose = require('mongoose');
const bcrypt = require('bcrypt');

const ADMIN_NAME = process.env.ADMIN_NAME || '$ADMIN_NAME';
const ADMIN_EMAIL = process.env.ADMIN_EMAIL || '$ADMIN_EMAIL';
const ADMIN_PASSWORD = process.env.ADMIN_PASSWORD || '$ADMIN_PASSWORD';
const MONGO_URL = process.env.MONGO_URL || 'mongodb://localhost:27017/eventix';

// Define User Schema inline (or import from actual model)
const userSchema = new mongoose.Schema({
  name: String,
  email: String,
  password: String,
  role: String,
  isApproved: Boolean,
  adminRequestStatus: String,
  createdAt: Date,
  updatedAt: Date
});

const User = mongoose.model('User', userSchema);

async function createSuperAdmin() {
  try {
    // Connect to MongoDB
    await mongoose.connect(MONGO_URL, {
      useNewUrlParser: true,
      useUnifiedTopology: true
    });
    console.log('✓ Connected to MongoDB');

    // Check if superAdmin already exists
    const existing = await User.findOne({ role: 'superAdmin' });
    if (existing) {
      console.log('⚠️  SuperAdmin already exists:');
      console.log('   Name: ' + existing.name);
      console.log('   Email: ' + existing.email);
      process.exit(1);
    }

    // Hash password
    const hashedPassword = await bcrypt.hash(ADMIN_PASSWORD, 10);

    // Create superAdmin
    const superAdmin = new User({
      name: ADMIN_NAME,
      email: ADMIN_EMAIL,
      password: hashedPassword,
      role: 'superAdmin',
      isApproved: true,
      adminRequestStatus: 'none',
      createdAt: new Date(),
      updatedAt: new Date()
    });

    await superAdmin.save();

    console.log('');
    console.log('✓ SuperAdmin created successfully!');
    console.log('');
    console.log('Login Credentials:');
    console.log('==================');
    console.log('Email: ' + ADMIN_EMAIL);
    console.log('Password: [Your entered password]');
    console.log('');
    console.log('Features:');
    console.log('- Can approve/reject admin requests');
    console.log('- Can manage platform settings');
    console.log('- Can create and manage events');
    console.log('- Can book events');
    console.log('');

    process.exit(0);
  } catch (err) {
    console.error('❌ Error creating SuperAdmin:');
    console.error(err.message);
    process.exit(1);
  }
}

createSuperAdmin();
EOF

echo ""
echo "================================"
echo "✓ SuperAdmin setup complete!"
echo "================================"
echo ""
echo "Next steps:"
echo "1. Start your backend: npm start"
echo "2. Start your frontend: npm start"
echo "3. Visit registration page"
echo "4. Login with SuperAdmin credentials"
echo "5. Go to Dashboard → Admin Requests"
echo "6. Approve/Reject pending admin requests"
echo ""
