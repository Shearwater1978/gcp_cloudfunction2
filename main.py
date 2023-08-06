import base64
import functions_framework
import json

# Triggered from a message on a Cloud Pub/Sub topic.
@functions_framework.cloud_event
def main(cloud_event):
    # Print out the data from Pub/Sub, to prove that it worked
    # rawPayLoad = base64.b64decode(cloud_event.data["message"]["data"])
    # payLoadJson = json.loads(rawPayLoad)
    print(base64.b64decode(cloud_event.data["message"]["data"]))
    # print(payLoadJson['protoPayload']['authenticationInfo']['principalEmail'])

