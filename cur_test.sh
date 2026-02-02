# 1. Get the Random Suffix (u4ecju or similar)
SUFFIX=$(terraform state show random_string.suffix | grep result | awk '{print $3}' | tr -d '"')

# 2. Get the Tenant ID
TENANT_ID=$(terraform output -raw tenant_id)

# 3. Get the Client ID (Application ID)
CLIENT_ID=$(terraform output -raw aad_client_id)

# 4. Construct the Scope URI
SCOPE="api://mcp-gateway-${SUFFIX}/access_as_user"

echo "Configured for:"
echo "Tenant: $TENANT_ID"
echo "Client: $CLIENT_ID"
echo "Scope:  $SCOPE"

#az login --tenant $TENANT_ID --scope $SCOPE --use-device-code

curl -v -H "Authorization: Bearer $TOKEN" \
  -H "Accept: text/event-stream" \
  https://apim-mcp-${SUFFIX}.azure-api.net/mslearn/sse

#curl -v -X POST   -H "Authorization: Bearer $TOKEN"   -H "Content-Type: application/json"   -H "Ocp-Apim-Subscription-Key: $SUBSCRIPTION_KEY"   -d '{
#    "jsonrpc": "2.0",
#    "method": "ping",
#    "id": 1
#  }'   "https://apim-mcp-${SUFFIX}.azure-api.net/mslearn/messages"
#
#
#curl -v -X POST   -H "Authorization: Bearer $TOKEN"   -H "Content-Type: application/json"   -H "Ocp-Apim-Subscription-Key: $SUBSCRIPTION_KEY"   -d '{
#    "jsonrpc": "2.0",
#    "method": "tools/list",
#    "id": 2
#  }'   "https://apim-mcp-${SUFFIX}.azure-api.net/mslearn/messages"

#curl -v -X POST \
#  -H "Authorization: Bearer $TOKEN" \
#  -H "Content-Type: application/json" \
#  -H "Ocp-Apim-Subscription-Key: $SUBSCRIPTION_KEY" \
#  -d '{
#    "jsonrpc": "2.0",
#    "method": "tools/call",
#    "params": {
#      "name": "microsoft_docs_search",
#      "arguments": {
#        "query": "create azure virtual machine"
#      }
#    },
#    "id": 3
#  }' \
#  "https://apim-mcp-${SUFFIX}.azure-api.net/mslearn/messages"
