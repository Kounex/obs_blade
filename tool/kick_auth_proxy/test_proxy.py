#!/usr/bin/env python3
"""Unit tests for the token-exchange rules. No network."""

import os
import unittest

os.environ["KICK_OAUTH_CLIENT_ID"] = "client-1"
os.environ["KICK_OAUTH_CLIENT_SECRET"] = "secret-1"

import proxy  # noqa: E402

proxy.CLIENT_ID = "client-1"
proxy.CLIENT_SECRET = "secret-1"


class BuildUpstreamTest(unittest.TestCase):
    def test_authorization_code_injects_the_secret_and_pins_the_redirect(self):
        form = proxy.build_upstream(
            {
                "grant_type": "authorization_code",
                "client_id": "ignored",
                "client_secret": "ignored",
                "code": "code-1",
                "code_verifier": "verifier-1",
                "redirect_uri": "https://localhost/kick-callback",
            }
        )
        self.assertEqual(form["client_id"], "client-1")
        self.assertEqual(form["client_secret"], "secret-1")
        self.assertEqual(form["redirect_uri"], "https://localhost/kick-callback")
        self.assertNotIn("ignored", form.values())

    def test_wrong_redirect_is_rejected(self):
        with self.assertRaises(proxy.ProxyError) as caught:
            proxy.build_upstream(
                {
                    "grant_type": "authorization_code",
                    "code": "code-1",
                    "code_verifier": "verifier-1",
                    "redirect_uri": "https://evil.example/callback",
                }
            )
        self.assertEqual(caught.exception.status, 400)

    def test_refresh_drops_anything_except_the_refresh_token(self):
        form = proxy.build_upstream(
            {
                "grant_type": "refresh_token",
                "refresh_token": "refresh-1",
                "client_secret": "nope",
                "redirect_uri": "https://evil.example/callback",
            }
        )
        self.assertEqual(
            set(form),
            {"grant_type", "client_id", "client_secret", "refresh_token"},
        )
        self.assertEqual(form["refresh_token"], "refresh-1")

    def test_unknown_grant_is_rejected(self):
        with self.assertRaises(proxy.ProxyError):
            proxy.build_upstream({"grant_type": "client_credentials"})

    def test_rate_limit_trips_after_the_window_budget(self):
        proxy._hits.clear()
        for _ in range(proxy.MAX_PER_WINDOW):
            self.assertTrue(proxy._allow("203.0.113.5", now=1000))
        self.assertFalse(proxy._allow("203.0.113.5", now=1000))
        self.assertTrue(proxy._allow("203.0.113.9", now=1000))


if __name__ == "__main__":
    unittest.main()
