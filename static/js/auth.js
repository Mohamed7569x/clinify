// ==== Monitoring System Auth Helper ====

let msAccessToken = null;       // in-memory only
let msTokenType = "bearer";
let msIsRefreshing = false;
let msRefreshPromise = null;

// Set current access token from login / refresh
function setAccessToken(token, type = "bearer") {
  msAccessToken = token;
  msTokenType = type || "bearer";
}

// Clear auth (used on logout / hard 401)
function clearAuth() {
  msAccessToken = null;
  msTokenType = "bearer";
}

async function refreshAccessToken() {
  if (msIsRefreshing && msRefreshPromise) {
    return msRefreshPromise;
  }

  msIsRefreshing = true;
  msRefreshPromise = (async () => {
    const headers = {
      "Accept": "application/json"
    };

    if (msAccessToken) {
      headers["Authorization"] = `${msTokenType} ${msAccessToken}`;
    }

    const res = await fetch("/api/v1/auth/refresh/", {
      method: "POST",
      credentials: "include",
      headers
    });

    if (!res.ok) {
      clearAuth();
      throw new Error("Failed to refresh token");
    }

    const data = await res.json();
    const accessToken = data.access_token || data.token;
    const tokenType = data.token_type || "bearer";

    if (!accessToken) {
      clearAuth();
      throw new Error("No access token in refresh response");
    }

    setAccessToken(accessToken, tokenType);
    return accessToken;
  })();

  try {
    return await msRefreshPromise;
  } finally {
    msIsRefreshing = false;
    msRefreshPromise = null;
  }
}

async function getValidAccessToken() {
  if (msAccessToken) return msAccessToken;
  return await refreshAccessToken();
}

async function authfetch(url, options = {}) {
  try {
    const token = await getValidAccessToken();

    const headers = {
      ...(options.headers || {}),
      "Authorization": `${msTokenType} ${token}`
    };

    const finalOptions = {
      ...options,
      headers,
      credentials: "include"
    };

    const res = await fetch(url, finalOptions);
    if (res.status === 401 || res.status === 403) {
      clearAuth();
      try {
        await fetch("/api/v1/auth/logout/", {
          method: "POST",
          credentials: "include"
        });
      } catch (_) {}
      window.location.href = "/login";
      throw new Error("Unauthorized");
    }

    return res;
  } catch (err) {
    console.error("authFetch error:", err);
    clearAuth();
    window.location.href = "/login";
    throw err;
  }
}

// Called at page load for protected pages
async function ensureAuthenticated() {
  try {
    await getValidAccessToken();
    return true;
  } catch (err) {
    // redirect handled already
    return false;
  }
}
