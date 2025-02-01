# Attribution Service API Specification

## Base URL

`https://api.reddimon.com/v1`

## Authentication

All requests must include an API key in the Authorization header:

`Authorization: Bearer <YOUR_API_KEY_HERE>`

## Endpoints

### Track Installation

`POST /install`

Tracks new app installations with attribution data.

**Request Body:**

```
json
{
"install_timestamp": 1234567890,
"device_type": "iPhone",
"ios_version": "15.0",
"app_version": "1.0.0",
"device_id": "XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX",
"app_id": "com.yourapp.id",
"screen_resolution": "1170x2532",
"timezone": "America/New_York",
"language": "en",
"ip_address": "xxx.xxx.xxx.xxx",
"creator_id": "123", // From attribution link
"campaign": "summer" // From attribution link
}
```

**Response:**

```
json
{
"status": "success"
}
```

### Track Conversion

`POST /conversion`

Tracks user conversions such as subscriptions or feature activations.

**Request Body:**

```
json
{
"conversion_type": "subscription",
"timestamp": 1234567890,
"device_id": "XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX",
"value": 99.99, // Optional
"currency": "USD", // Optional
"creator_id": "123", // From attribution
"campaign": "summer" // From attribution
}
```

json
{
"success": true,
"conversion_id": "conv_xxxxxxxxxxxxx"
}
