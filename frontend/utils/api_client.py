# jalamart_frontend/utils/api_client.py
import requests
import json
import os
from flask import current_app, session

class APIClient:
    """
    A client for interacting with the JalaMart backend API.
    Handles requests, token management, and error responses.
    """
    def __init__(self, base_url=None):
        # If base_url is not provided, try to get it from current_app config
        self.base_url = base_url if base_url else current_app.config.get('BACKEND_API_BASE_URL')
        if not self.base_url:
            raise ValueError("BACKEND_API_BASE_URL is not set. Please set it in your Flask config or .env.")

    def _get_headers(self, include_auth=True):
        """Constructs request headers, optionally including the JWT token."""
        headers = {
            'Content-Type': 'application/json',
            'Accept': 'application/json'
        }
        if include_auth and 'token' in session:
            headers['Authorization'] = f"Bearer {session['token']}"
        return headers

    def _handle_response(self, response):
        """Handles API responses, raises exceptions for errors, and returns JSON data."""
        try:
            response.raise_for_status()  # Raises HTTPError for bad responses (4xx or 5xx)
            return response.json()
        except requests.exceptions.HTTPError as e:
            # Attempt to parse backend error message
            try:
                error_data = response.json()
                message = error_data.get('message', 'An unknown error occurred.')
                if 'errors' in error_data: # For validation errors
                    message = ", ".join([f"{k}: {v}" for k, v in error_data['errors'].items()])
            except json.JSONDecodeError:
                message = response.text or str(e) # Fallback to raw text or HTTPError message

            status_code = response.status_code

            # Map common HTTP errors to more specific messages for the frontend
            if status_code == 400:
                raise APIError(f"Bad Request: {message}", status_code=status_code)
            elif status_code == 401:
                # Clear token on unauthorized access, redirect to login
                if 'token' in session:
                    session.pop('token')
                    session.pop('user', None)
                    session.pop('cart_item_count', 0)
                raise APIError(f"Unauthorized: {message}", status_code=status_code)
            elif status_code == 403:
                raise APIError(f"Forbidden: {message}", status_code=status_code)
            elif status_code == 404:
                raise APIError(f"Not Found: {message}", status_code=status_code)
            elif status_code >= 500:
                raise APIError(f"Server Error: {message}", status_code=status_code)
            else:
                raise APIError(f"API Error ({status_code}): {message}", status_code=status_code)
        except requests.exceptions.ConnectionError:
            raise APIError("Cannot connect to the backend API. Please check the server status.", status_code=503)
        except requests.exceptions.Timeout:
            raise APIError("The request to the backend API timed out.", status_code=408)
        except Exception as e:
            raise APIError(f"An unexpected error occurred during API communication: {e}", status_code=500)

    def get(self, path, params=None, include_auth=True):
        """Sends a GET request to the API."""
        url = f"{self.base_url}{path}"
        response = requests.get(url, headers=self._get_headers(include_auth), params=params)
        return self._handle_response(response)

    def post(self, path, data=None, include_auth=True):
        """Sends a POST request to the API."""
        url = f"{self.base_url}{path}"
        response = requests.post(url, headers=self._get_headers(include_auth), json=data)
        return self._handle_response(response)

    def put(self, path, data=None, include_auth=True):
        """Sends a PUT request to the API."""
        url = f"{self.base_url}{path}"
        response = requests.put(url, headers=self._get_headers(include_auth), json=data)
        return self._handle_response(response)

    def delete(self, path, include_auth=True):
        """Sends a DELETE request to the API."""
        url = f"{self.base_url}{path}"
        response = requests.delete(url, headers=self._get_headers(include_auth))
        return self._handle_response(response)

# Custom exception for API errors
class APIError(Exception):
    def __init__(self, message, status_code=None):
        super().__init__(message)
        self.message = message
        self.status_code = status_code