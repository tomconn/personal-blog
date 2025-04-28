# personal-blog
Personal blog


Detailed steps to get your Hugo blog, which you manage locally with Docker Compose, built and deployed by Cloudflare Pages and served securely over HTTPS on `https://blog.softwarestable.com`. We'll also touch on how Cloudflare Workers can fit in.

**Assumptions:**

1.  Your Hugo project source code (content, layouts, static, `config.toml`, etc.) is in a Git repository (GitHub, GitLab, Bitbucket).
2.  You have a Cloudflare account.
3.  Your domain `softwarestable.com` is already added to your Cloudflare account and uses Cloudflare's nameservers for DNS management.
4.  You know the specific Hugo version you are using in your Docker setup (e.g., `0.119.0`). You can find this in your `docker-compose.yml` or the `docker run` command you use.

**Phase 1: Configure Hugo for Production**

This step ensures Hugo generates correct absolute URLs for your production site.

1.  **Set `baseURL` in Hugo Config:**
    *   Open your Hugo project's configuration file (`config.toml`, `hugo.toml`, `config.yaml`, etc.).
    *   Find the `baseURL` setting.
    *   **Change it to your final production URL:**
        ```toml
        # In config.toml or hugo.toml
        baseURL = "https://blog.softwarestable.com/"
        ```
        *Make sure it includes `https://` and the trailing slash `/`.*
2.  **Commit and Push Changes:**
    *   Save the configuration file.
    *   Commit this change to your Git repository:
        ```bash
        git add config.toml # Or hugo.toml, etc.
        git commit -m "Configure baseURL for production (blog.softwarestable.com)"
        git push origin main # Or your default branch
        ```

**Phase 2: Configure Cloudflare Pages**

This is where Cloudflare connects to your Git repo, builds the Hugo site, and hosts the static files.

1.  **Log in to Cloudflare Dashboard:** Go to [dash.cloudflare.com](https://dash.cloudflare.com).
2.  **Navigate to Pages:** In the left sidebar, go to `Workers & Pages`.
3.  **Create a Pages Project:**
    *   Click `Create application`.
    *   Select the `Pages` tab.
    *   Click `Connect to Git`.
4.  **Connect Git Provider:**
    *   Choose the Git provider hosting your Hugo project (GitHub, GitLab).
    *   Authenticate and authorize Cloudflare to access your repositories if prompted.
    *   Select the specific repository containing your Hugo blog source code.
    *   Click `Begin setup`.
5.  **Configure Build Settings:** This is the most critical step for Hugo.
    *   **Project name:** Choose a name (e.g., `blog-softwarestable-com`). This partly determines your default `*.pages.dev` subdomain, but you'll use a custom domain anyway.
    *   **Production branch:** Select the branch Cloudflare should build from (usually `main` or `master`).
    *   **Framework preset:** Select **`Hugo`** from the dropdown. This sets helpful defaults.
    *   **Build command:** Cloudflare should automatically suggest `hugo` or similar based on the preset. For a production build, you might want to explicitly set it to include optimizations: `hugo --gc --minify`
    *   **Build output directory:** Cloudflare should automatically set this to `public` based on the Hugo preset. This is correct.
    *   **Root directory (advanced):** Leave blank unless your Hugo project is in a subdirectory *within* your Git repository.
    *   **Environment Variables (Build & deployments):** This is ESSENTIAL for ensuring Cloudflare uses the *correct Hugo version*.
        *   Click `Add variable`.
        *   Variable name: `HUGO_VERSION`
        *   Value: Enter the **exact** Hugo version number you use locally in Docker (e.g., `0.119.0`). Using the *same version* prevents build inconsistencies.
        *   Click `Save`. You can add other build-time variables here if needed.
6.  **Save and Deploy:**
    *   Review the settings.
    *   Click `Save and Deploy`.
    *   Cloudflare will now clone your repository, run the build command (using the specified Hugo version), and deploy the contents of the `public` directory to its edge network.
    *   You can monitor the build progress in the Pages project dashboard. The first build might take a minute or two.
    *   Once complete, your site will be live on a default `*.pages.dev` URL.

**Phase 3: Add Custom Domain**

Now, point `blog.softwarestable.com` to your deployed Cloudflare Pages site.

1.  **Go to Your Pages Project:** Navigate back to the dashboard for the Pages project you just created.
2.  **Select "Custom domains" Tab:** Click on the `Custom domains` tab within the project settings.
3.  **Click "Set up a domain":**
4.  **Enter Your Subdomain:** Type `blog.softwarestable.com` into the box and click `Continue`.
5.  **Verify DNS Record:**
    *   Cloudflare will automatically detect that `softwarestable.com` is managed by Cloudflare DNS.
    *   It will show you the `CNAME` record it needs. It will likely be:
        *   Type: `CNAME`
        *   Name: `blog`
        *   Target/Content: Your unique Pages project URL (e.g., `your-project-name.pages.dev`)
        *   Proxy status: Proxied (Orange Cloud) - This is usually recommended.
    *   **Action:** Go to your Cloudflare dashboard -> Select `softwarestable.com` domain -> `DNS` -> `Records`. **Cloudflare Pages often adds this CNAME record automatically for you if the domain is already in the same account.** Check if it exists. If not, add it exactly as shown in the Pages setup instructions.
6.  **Activate Domain:** Back in the Pages "Custom domains" setup, click `Activate domain`.
    *   Cloudflare will check for the correct DNS record. This might take a few seconds to a few minutes.
    *   It will also automatically provision and manage an SSL/TLS certificate for `blog.softwarestable.com`, ensuring HTTPS works correctly.
    *   Once verified and the certificate is issued, the status will change to "Active".

**Phase 4: Test**

1.  Wait a few minutes for DNS changes to propagate globally (though changes within Cloudflare DNS are usually very fast).
2.  Open your browser and navigate to `https://blog.softwarestable.com`.
3.  Verify that your Hugo blog loads correctly with your theme and content, served over HTTPS.

**Phase 5: Understanding Cloudflare Workers Integration (Optional)**

Cloudflare Workers run serverless JavaScript code on Cloudflare's edge. They can intercept requests *before* they hit your static Pages site. You don't *need* them for a basic Hugo blog, but they can add dynamic functionality.

**How Workers Can Be Used with Pages:**

1.  **Pages Functions (Recommended Integration):**
    *   **Concept:** You write Worker code within a specific `functions` directory *inside your Hugo project repository*.
    *   **Structure:**
        ```
        my-hugo-blog/
        ├── content/
        ├── layouts/
        ├── static/
        ├── functions/  <-- Worker code goes here
        │   ├── api/
        │   │   └── submit-form.js  # Example: Handles POST requests to /api/submit-form
        │   └── _middleware.js      # Example: Runs on all requests
        └── config.toml
        ```
    *   **Deployment:** Cloudflare Pages automatically detects the `functions` directory during the build and deploys your Worker code alongside your static assets. Requests matching the file paths in `functions` (or all requests if using `_middleware.js`) will execute the Worker code.
    *   **Use Cases:** Handling form submissions, basic API endpoints, simple redirects/rewrites, adding security headers.

2.  **Standalone Worker + Route (More Advanced):**
    *   **Concept:** You create a Worker script separately in the Cloudflare dashboard (Workers & Pages -> Overview -> Create Worker). Then, you create a Route that directs traffic for your site to that Worker.
    *   **Route:** You would add a route like `blog.softwarestable.com/*` and assign it to your created Worker script.
    *   **Worker Logic:** The Worker code would need logic to decide whether to handle the request itself (e.g., for an API call) or fetch the corresponding static asset from Cloudflare Pages (`fetch(request)` might automatically fall through to the Pages asset if the Worker doesn't return a Response).
    *   **Use Cases:** More complex routing logic, sharing a Worker across multiple sites/subdomains, A/B testing, full edge-rendered applications.

**Recommendation:** For adding simple dynamic features to your Hugo blog hosted on Pages, start with **Pages Functions**. It's the most straightforward and integrated approach. You only need to explore standalone Workers if you have more complex requirements.

**Summary Workflow:**

1.  Update `baseURL` in `config.toml` to `https://blog.softwarestable.com/`.
2.  Commit and push source code changes to Git.
3.  Create Cloudflare Pages project, connect to Git repo.
4.  Configure build settings: Hugo preset, `hugo --gc --minify`, **`HUGO_VERSION` environment variable**.
5.  Save and Deploy.
6.  Add `blog.softwarestable.com` as a custom domain in Pages settings.
7.  Verify/add the `CNAME` record in Cloudflare DNS for `softwarestable.com`.
8.  Activate the custom domain in Pages.
9.  (Optional) Add dynamic features later using Pages Functions by creating a `functions` directory in your repo.

Your Hugo blog is now built automatically by Cloudflare Pages whenever you push to your production branch and served securely from the edge on your custom domain!