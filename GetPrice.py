import requests
import pyodbc
from datetime import datetime
conn=pyodbc.connect('DRIVER={SQL Server};server=IND-WJJ0203;database=TallPines; Trusted_Connection=yes;')
url = 'https://api.binance.com/api/v1/ticker/price'

response = requests.get(url)
JSONdata = response.json()
runtime = datetime.now()
cursor = conn.cursor()

for ticker in JSONdata:
    cursor.execute('Exec Crypto.AddPrice @Ticker = ?, @Price = ?, @RunTime = ?', ticker['symbol'], ticker['price'], runtime)
    conn.commit()


