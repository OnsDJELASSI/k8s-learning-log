import os
from functools import wraps
from urllib.parse import urlencode

import jwt
from authlib.integrations.flask_client import OAuth
from flask import Flask, abort, redirect, session, url_for

KC = "http://localhost:8080/realms/lab"

app = Flask(__name__)
app.secret_key = os.urandom(24)
oauth = OAuth(app)
oauth.register(
    name="keycloak",
    client_id="test-app",
    server_metadata_url=f"{KC}/.well-known/openid-configuration",
    client_kwargs={
        "scope": "openid profile email",
        "code_challenge_method": "S256",
        "token_endpoint_auth_method": "none",
    },
)


def require_role(role=None):
    def deco(fn):
        @wraps(fn)
        def wrapper(*args, **kwargs):
            user = session.get("user")
            if not user:
                return redirect(url_for("login"))
            if role and role not in user["roles"]:
                abort(403)
            return fn(*args, **kwargs)

        return wrapper

    return deco


@app.route("/")
def home():
    user = session.get("user")
    if not user:
        return '<h1>Lab Keycloak</h1><a href="/login">Se connecter</a>'
    return (
        f"<h1>Bonjour {user['name']}</h1>"
        f"<p>Roles : {', '.join(user['roles'])}</p>"
        '<p><a href="/profile">Profil (tout utilisateur connecté)</a></p>'
        '<p><a href="/admin">Zone admin (role admin)</a></p>'
        '<p><a href="/logout">Déconnexion</a></p>'
    )


@app.route("/login")
def login():
    return oauth.keycloak.authorize_redirect(url_for("callback", _external=True))


@app.route("/callback")
def callback():
    token = oauth.keycloak.authorize_access_token()
    # Lab : lecture des roles dans l'access token recu directement du serveur
    claims = jwt.decode(token["access_token"], options={"verify_signature": False})
    roles = claims.get("realm_access", {}).get("roles", [])
    session["user"] = {
        "name": token["userinfo"].get("preferred_username"),
        "roles": [r for r in roles if r in ("admin", "user")],
    }
    return redirect("/")


@app.route("/profile")
@require_role()
def profile():
    return f"<h1>Profil</h1><p>{session['user']}</p><a href='/'>Retour</a>"


@app.route("/admin")
@require_role("admin")
def admin():
    return "<h1>Zone admin</h1><p>Accès autorisé : role admin.</p><a href='/'>Retour</a>"


@app.route("/logout")
def logout():
    session.clear()
    q = urlencode({"client_id": "test-app", "post_logout_redirect_uri": "http://localhost:3000/"})
    return redirect(f"{KC}/protocol/openid-connect/logout?{q}")


if __name__ == "__main__":
    app.run(host="127.0.0.1", port=3000)
