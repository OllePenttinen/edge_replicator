# Function Replicator Edge App (IoT Open)

This Edge App monitors selected functions (by name pattern) in Installation A.
When values are updated:
- If value > 0 → the function is copied to Installation B
- If value = 0 → the function is removed from Installation B

## Configuration
| Parameter | Description | Example |
|------------|--------------|----------|
| `destination_installation` | ID of the destination installation | `"install_ABC123"` |
| `function_patterns` | Wildcard patterns for functions to watch | `["sensor.temperature.*", "relay.*"]` |

## How it works
1. App subscribes to all function value updates.
2. Each updated function is checked against your wildcard patterns.
3. Matching functions are copied or deleted in Installation B based on their value.

## Deployment
1. Create a new Edge App in IoT Open.
2. Upload `app.lua` and `config.json`.
3. Publish a version.
4. Deploy to your edge gateway on Installation A.
5. Configure the parameters in the UI.
