# import telebot


# BOT_TOKEN = '7864800313:AAFyuO5as3DDS78_3V5oTjz0Xa8sEASraPg'
# bot = telebot.TeleBot(BOT_TOKEN)
# chat_id = ''

# @bot.message_handler(commands=['start', 'hello'])
# def send_welcome(message):
#     print(message)
#     bot.reply_to(message,
#                  """Bot Tasks\n/status - Check Points""")
    
    
# bot.infinity_polling()

import requests

headers = {"Authorization": f"Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJmY3A5NjY1NjY4NDg0NTEiLCJwYXNzd29yZCI6IjE4OTcwMzM0ODYiLCJyb2xlIjoidXNlciIsImV4cCI6MTczNTQyNTIwNCwidG9rZW5fdHlwZSI6ImFjY2VzcyJ9.LTWFb2-idUOy9-oKfC-v7RYh7V5tZTZu2HHbb4ZaKQY"}
response = requests.get('http://127.0.0.1:8000/api/v1/user/mh_status', headers=headers)
print(response.text)