---
title: "Build an Complete Personal Website with Cloudflare Pages"
date: 2025-04-28T19:30:00Z
draft: false # publish
tags: ["hugo", "cloudflare", "serverless", "website"]
---

Ever dreamt of running a dynamic website with user logins, persistent storage, and lightning-fast global delivery without paying a hefty hosting bill? It sounds too good to be true, right? Wrong! Welcome to the world of Cloudflare Pages and Workers, a powerful duo that lets you build and deploy sophisticated web applications often entirely within Cloudflare's **generous free tier**.

**What are Cloudflare Pages & Workers?**

*   **Cloudflare Pages:** Think of this as supercharged static web hosting. You connect your Git repository (like GitHub), and Cloudflare automatically builds and deploys your HTML, CSS, and JavaScript files to its massive global network (CDN). This means your website loads incredibly fast for users anywhere in the world.
*   **Cloudflare Workers:** These are your serverless backend functions. They run JavaScript code on Cloudflare's edge network, close to your users. Instead of managing servers, you just write code to handle tasks like processing form submissions, interacting with APIs, authenticating users, or querying databases – and Cloudflare handles the rest.

When combined, Pages serve your fast frontend, and Workers provide the dynamic backend logic, creating a seamless and powerful application architecture.

## Purpose of This Guide

This blog post dives into how you can leverage Cloudflare's ecosystem to build a fully functional website. We'll explore:

* **Cloudflare Pages:** Hosting your static website content (HTML, CSS, JS).
* **Cloudflare Workers:** Implementing serverless functions for dynamic tasks like user registration and login.
* **Cloudflare D1:** Utilizing Cloudflare's native serverless SQL database for persistent storage (like user credentials).
* **DNS Management:** Setting up Cloudflare Pages with either Cloudflare DNS or your own custom domain name registered elsewhere (like Namecheap), while potentially keeping external email forwarding intact.
* **GitOps Workflow:** Demonstrating how changes pushed to your Git repository automatically trigger deployments of both your website and your backend functions, making updates simple and reliable.

We'll use a real-world example: a personal website that includes user registration, login, and account activation features, all powered by Cloudflare.

## Building Blocks: A Practical Example

Let's break down the key steps involved in setting up a project like this, referencing code and configurations from an example personal website project.

### 1. Setting Up Your Code Repository (GitHub)

Everything starts with your code living in a Git repository. Cloudflare Pages hooks directly into GitHub (or GitLab).

*   **Why Git?** It provides version control and, crucially, acts as the trigger for Cloudflare's automatic deployments (GitOps).
*   **Process:**
    * Create a repository on GitHub (can be private).
    * Clone it to your local machine.
    * Add your website files (`index.html`, `style.css`, `script.js`) and your backend function code (typically in a `/functions` directory).
    * Commit and push your changes.

```bash
/
├── functions/                  # Backend Cloudflare Functions
│   ├── api/                    # API endpoint handlers
│   │   ├── register.js         # Handles user registration POST requests
│   │   ├── login.js            # Handles user login POST requests
│   │   ├── activate-account.js # Handles account activation POST requests
│   │   └── ...                 # Other API endpoints
│   └── utils/                  # Shared backend utility functions
│       ├── auth.js             # Hashing, tokens, cookies
│       └── email.js            # Email sending
│       └── validation.js       # Input validation
│
├── index.html                  # Main website page
├── login.html                  # Login form
├── register.html               # Registration form
├── style.css                   # Styles
└── script.js                   # Frontend JS for index.html
└── ...                         # Other frontend files
```

When you push changes to the designated branch (e.g., `main`), Cloudflare automatically picks them up, builds (if necessary), and deploys the updates globally.

### 2. Using Your Custom Domain (External DNS Example)

While Cloudflare offers DNS services, you might have your domain registered elsewhere (like Namecheap) and want to keep it there, especially if you use their email forwarding. Cloudflare Pages makes this easy.

* **Goal:** Point `www.yourdomain.com` to your Cloudflare Pages site without changing your domain's primary nameservers.
* **Process:**
    * In your Cloudflare Pages project settings, add your custom domain (e.g., `www.yourdomain.com`).
    * Cloudflare will provide a unique CNAME target value (e.g., `<your-project>.pages.dev`).
    * Log in to your DNS provider (Namecheap). Go to the DNS settings for your domain.
    * Add a `CNAME` record:
        *   **Host/Name:** `www`
        *   **Value/Target:** Paste the value Cloudflare provided.
        *   **TTL:** Set to Automatic or a low value (like 5 minutes).
    * Ensure no other `A` or `CNAME` records exist for the `www` host. **Leave your MX records untouched** to preserve external email flow.
    * Cloudflare will detect the change, validate the domain, and automatically provision an SSL certificate.

This setup lets Cloudflare handle the web hosting while your original provider continues managing DNS resolution and email.

### 3. Adding Login/Registration Capabilities (Cloudflare Workers)

Static sites are great, but web apps often need users. This is where Cloudflare Workers, integrated with Pages Functions, shine.

*   **How it works:** You create JavaScript files within the `/functions/api` directory (by convention). These files export handlers that respond to HTTP requests (GET, POST, etc.). Cloudflare deploys these alongside your static site.
*   **Example (`login.js`):** Handles POST requests to `/api/login`.
    *   Parses the incoming request body (email, password, reCAPTCHA token).
    *   Validates the input and the reCAPTCHA response.
    *   Queries the D1 database to find the user by email.
    *   Verifies the user is active and the provided password matches the stored hash (using a salt).
    *   If successful, generates a secure session token, stores it in the D1 `sessions` table, and sets a secure HTTP-only cookie in the user's browser.
    *   Returns a success or error JSON response.

Here's a snippet from the `login.js` Worker function:

```javascript
// File: functions/api/login.js

import { isValidEmail, verifyRecaptcha } from '../utils/validation.js';
import { verifyPassword, createSessionCookie, generateSecureToken } from '../utils/auth.js';

const SESSION_DURATION_SECONDS = 3 * 60 * 60; // 3 hours

export async function onRequestPost({ request, env }) {
    console.log("--- /api/login: Request received ---"); // Log start

    try {
        // --- Basic Setup & Input Parsing ---
        if (!env.DB) {
             console.error("/api/login: FATAL - D1 Database binding (DB) is not configured.");
             return new Response(
              JSON.stringify({ success: false, message: 'Server Error [db].' }), { status: 500 });
        }
        console.log("/api/login: DB binding found.");

        const body = await request.json();
        const email = body.email?.trim();
        const password = body.password;
        const recaptchaToken = body['g-recaptcha-response'];
        const ip = request.headers.get('CF-Connecting-IP');
        console.log(`/api/login: Attempting login for email: ${email}`);

        // --- Input Validation ---
        // ... (validation logic)

        // --- reCAPTCHA Verification ---
        // ... (reCAPTCHA check using env.RECAPTCHA_SECRET_KEY)

        // --- Find User ---
        console.log(`/api/login: Finding user by email: ${email}...`);
        const user = await env.DB.prepare(
            "SELECT id, email, password_hash, salt, is_active FROM users WHERE email = ?"
            )
            .bind(email)
            .first();

        if (!user || user.is_active !== 1) {
            console.warn(`/api/login: Login failed - User not found or inactive (${email})`);
            // Return 401 Unauthorized
        }
        console.log(`/api/login: User found. ID: ${user.id}, Active: ${user.is_active}`);

        // --- Verify Password ---
        const isPasswordValid = await verifyPassword(user.password_hash, user.salt, password);

        if (!isPasswordValid) {
            console.warn(`/api/login: Login failed - Invalid password (ID: ${user.id})`);
             // Return 401 Unauthorized
        }
        console.log(`/api/login: Password verified for user ID: ${user.id}.`);

        // --- Login Success: Generate Session Token & Store in D1 ---
        const sessionToken = generateSecureToken(32);
        const expires = new Date(Date.now() + SESSION_DURATION_SECONDS * 1000);
        const expiresISO = expires.toISOString();

        // Store the session in the database (uses env.DB binding)
         await env.DB.prepare(
            "INSERT INTO sessions (token, user_id, expires_at) VALUES (?1, ?2, ?3)"
         ).bind(sessionToken, user.id, expiresISO).run();
         console.log(`/api/login: Session stored successfully in D1 for user ${user.id}.`);


        // --- Set Session Cookie ---
        const cookieHeader = createSessionCookie(sessionToken);

        // --- Return Success Response with Cookie ---
        return new Response(JSON.stringify({ success: true, message: 'Login successful.' }), {
            status: 200,
            headers: {
                'Content-Type': 'application/json',
                'Set-Cookie': cookieHeader, // Set the session cookie
            }
        });

    } catch (error) {
        // ... (error handling)
    }
}
```

A similar function (`register.js`) handles user registration, hashing passwords with salts before storing them, and initiating the account activation process.

### 4. Storing User Data with D1 Database

Dynamic applications need persistent storage. Cloudflare D1 is a serverless SQL database built on SQLite, accessible directly from Workers.

*   **Purpose:** Store user credentials (email, hashed password, salt), activation status, session tokens, etc.
*   **Setup:**
    * Create a D1 database via the Cloudflare dashboard (Workers & Pages -> D1).
    * Define your table schemas using SQL. For authentication, you'd typically need:
        *   `users`: Stores user info like ID, email, password hash, salt, activation status/token.
        *   `sessions`: Stores active session tokens linked to user IDs with expiry times.

```sql
-- Users Table Schema
CREATE TABLE users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    email TEXT UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    salt TEXT NOT NULL,
    is_active INTEGER DEFAULT 0 NOT NULL, -- 0 = false, 1 = true
    activation_token TEXT,
    activation_expires DATETIME,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_activation_token ON users(activation_token);

-- Sessions Table Schema
CREATE TABLE sessions (
    token TEXT PRIMARY KEY NOT NULL,      -- The unique session token
    user_id INTEGER NOT NULL,             -- User ID linked to the session
    expires_at DATETIME NOT NULL,         -- Session expiry timestamp
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP, -- Session creation timestamp
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
CREATE INDEX idx_sessions_expires_at ON sessions(expires_at);
```

*   **Bind the Database:** In your Cloudflare Pages project settings (Settings -> Functions -> D1 database bindings), bind your D1 database to your functions. This makes it available via the `env.DB` object in your Worker code (as seen in the `login.js` example).
*   **Session Cleanup:** Since sessions expire, you need a mechanism to remove old ones. A separate Cloudflare Worker running on a Cron Trigger is ideal. This Worker periodically connects to the *same* D1 database and deletes rows from the `sessions` table where `expires_at` is in the past.


```javascript
/**
 * Cloudflare Worker script for cleaning up expired sessions from D1.
 * Triggered by a Cron schedule.
 */
export default {
  async scheduled(event, env, ctx) {
    console.log(`[Session Cleanup] Cron Trigger Fired: ${event.cron}`);
    ctx.waitUntil(cleanupExpiredSessions(env));
  },
};

async function cleanupExpiredSessions(env) {
  if (!env.SESSION_DB) { // Ensure binding name matches setup
    console.error("[Session Cleanup] D1 Database binding 'SESSION_DB' is missing.");
    return;
  }
  const nowISO = new Date().toISOString();
  console.log(`[Session Cleanup] Running cleanup at ${nowISO}...`);
  try {
    const stmt = env.SESSION_DB.prepare(
      "DELETE FROM sessions WHERE expires_at <= ?1"
    );
    const { success, meta } = await stmt.bind(nowISO).run();
    if (success) {
      console.log(`[Session Cleanup] Cleanup successful. Deleted ${meta.changes ?? 0} expired sessions.`);
    } else {
      console.error("[Session Cleanup] D1 query execution reported failure.", meta);
    }
  } catch (e) {
    console.error("[Session Cleanup] Error during cleanup:", e);
  }
}
```

### 5. Enabling Account Activation via Email

For registration, you often need to verify the user's email address. This requires sending an email with a unique activation link.

*   **Challenge:** Cloudflare Workers themselves don't send emails directly.
*   **Solution:** Use an external transactional email service (like Brevo (formerly Sendinblue), Mailgun, SendGrid, AWS SES).
*   **Process:**
    * Sign up for an email service and get API keys. Verify your sending domain/email address.
    * Store the API key and sender email address securely as Environment Variables in your Cloudflare Pages project settings (e.g., `EMAIL_API_KEY`, `NOTIFICATION_EMAIL_FROM`).
    * In your `register.js` Worker:
        *   After successfully creating the user record in D1 (with `is_active = 0` and an activation token/expiry), call a utility function (`sendEmail`).
        *   The `sendEmail` utility function (e.g., in `functions/utils/email.js`) uses `fetch` to make an API call to your chosen email service, passing the recipient's email, sender details, subject, and the email body containing the activation link (pointing to another Worker function like `/api/activate-account`).
    * The `/api/activate-account` function verifies the token from the link, checks its expiry against D1, and if valid, sets `is_active = 1` for the user in the database.

## Summary: Your Fully Functional and Free Website

By combining Cloudflare Pages for fast static hosting, Cloudflare Workers for serverless backend logic, and Cloudflare D1 for database storage, you can build surprisingly complex and robust web applications often entirely within the free tier.

The example discussed – a personal portfolio site enhanced with secure user registration, login, session management via D1, and email activation using an external gateway – demonstrates this power. The GitOps workflow ensures that deploying updates is as simple as pushing code. You get global distribution, serverless scalability, and potentially zero hosting costs.

Ready to explore the code yourself? Check out the full example project on GitHub:

[**https://github.com/tomconn/personal-website**](https://github.com/tomconn/personal-website)

Dive in, and see what amazing things you can build on the Cloudflare edge!