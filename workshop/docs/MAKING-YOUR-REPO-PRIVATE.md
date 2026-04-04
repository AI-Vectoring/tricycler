# Making Your Repository Private

<!-- [Tricycler] This entire guide applies to every tricycler stack.
     The Docker secret mechanism for injecting GITHUB_TOKEN is universal. -->

Start with a public repo as described in [GETTING-STARTED.md](GETTING-STARTED.md). When you are ready to make it private, follow this guide.

tricycler projects start public by default — it's the simplest path. This guide covers converting to private when you're ready.

---

## Why extra steps are needed

The dev container uses VS Code's GitHub authentication — no extra work there.

The stage, prod, and debug containers clone your repository from scratch during `docker build`, without any VS Code session. For a private repo, Docker needs a token to authenticate that clone.

<!-- [Think] The token is injected via Docker BuildKit secrets (--secret id=github_token).
     This means the token is never baked into the image layer — it is only available
     during the RUN step that performs the clone. Safe to push to a registry. -->

---

## Step 1 — Create a GitHub Personal Access Token

1. Go to **github.com → Settings → Developer settings → Personal access tokens → Fine-grained tokens**
2. Click **"Generate new token"**
3. Set a name (e.g. `my-project-docker-build`)
4. Set expiration — tokens expire 1 year from creation, regardless of use. When it expires, `make stage`, `make prod`, and `make debug` will fail with an auth error. Rotate the token before that happens by repeating this step and updating your shell profile.
5. Under **Repository access**, select your repository
6. Under **Permissions → Contents**, select **Read-only**
7. Click **"Generate token"** and copy it immediately — GitHub will not show it again

---

## Step 2 — Add the token to your shell profile

On your **host machine**:

```bash
# ~/.bashrc or ~/.zshrc
export GITHUB_TOKEN=ghp_xxxx
```

Reload your shell:

```bash
source ~/.bashrc   # or ~/.zshrc
```

Verify it works:

```bash
curl -s -H "Authorization: token $GITHUB_TOKEN" https://api.github.com/user | grep '"login"'
```

If it prints your GitHub username, you're good.

---

## Step 3 — Make the repo private on GitHub

1. Go to your repository → **Settings** → scroll to **Danger Zone**
2. Click **"Change repository visibility"** → **"Change to private"**
3. Type your repository name to confirm and click **"I want to make this repository private"**

From this point, `make stage`, `make prod`, and `make debug` will use your token automatically.

---

## Token expiration

<!-- [Think] Token rotation is the most common cause of broken builds in private repos.
     Add a calendar reminder when you create the token. -->

When your token expires:

1. Go to **github.com → Settings → Developer settings → Personal access tokens**
2. Generate a new token (same settings as Step 1)
3. Update your shell profile and reload: `source ~/.bashrc`
