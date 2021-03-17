import os
import logging
from json import dumps, loads
from urllib.request import Request, urlopen
from urllib.parse import urlencode
import boto3

client = boto3.client('ssm')

logger = logging.getLogger()
logger.setLevel(logging.INFO)

token_parameter = client.get_parameter(Name='/production/TELEGRAM_BOT_TOKEN', WithDecryption=True)
TELEGRAM_BOT_TOKEN = token_parameter['Parameter']['Value']
TELEGRAM_CHANNEL_ID = os.environ['TELEGRAM_CHANNEL_ID']
TELEGRAM_URL = "https://api.telegram.org/bot{}/sendMessage".format(TELEGRAM_BOT_TOKEN)

def process_message(message):
    try:
        output = loads(message)
    except:
        output = f"Payload was {type(message)}, not a JSON string...?\n\n```\n{message}\n```"
    return output

def handler(event, context):
    logger.info(f"event ({type(event)}) = {dumps(event)}")

    try:
        message = process_message(event['Records'][0]['Sns']['Message'])

        if 'AlarmName' in message:
            emoji = "⚠️" if message['NewStateValue'] == "ALARM" else "👏"
            message = f"{emoji} {message['AlarmDescription']}\n{message['NewStateReason']}\n\nhttps://console.aws.amazon.com/cloudwatch/home?region=us-east-1#alarmsV2:alarm/{message['AlarmName']}?"
        elif 'Deployment' in message:
            emoji = {
                "Success": "✅",
                "Failed": "❌",
                "Started": "🕔"
            }[message['Status']]
            message = f"{emoji} Deployment ({message['Deployment']}/{message['SHA']})\n🚀 {message['Status']} ‣ [View on GitHub]({message['Link']})"
        else:
            message = f"Unknown message type:\n\n```\n{dumps(message, indent=2)}\n```"

        payload = {
            "text": message,
            "chat_id": TELEGRAM_CHANNEL_ID,
            "parse_mode": "markdown"
        }

        request = Request(TELEGRAM_URL, data=bytes(urlencode(payload), 'utf-8'), method='POST')
        response = urlopen(request, timeout=3)

    except Exception as e:
        raise e
