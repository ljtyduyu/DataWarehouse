#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import time
import numpy   as np
import pandas  as pd 
import savReaderWriter as spss
import os
from  datetime import datetime,timedelta 
np.random.seed(233333)

os.chdir('D:/R/File') 

pd.set_option('display.float_format', lambda x: '%.3f' % x) 

with spss.SavReader('trade.sav',returnHeader = True ,ioUtf8=True,rawMode = True,ioLocale='chinese') as reader:
	mydata = pd.DataFrame(list(reader)[1:],columns = list(reader)[0])
	mydata['交易日期'] = mydata['交易日期'].map(lambda x: reader.spss2strDate(x,"%Y-%m-%d", None))
	mydata.rename(columns={'订单ID':'OrderID','客户ID':'UserID','交易日期':'PayDate','交易金额':'PayAmount'},inplace=True)
	start_time = int(time.mktime(time.strptime('2017/01/01', '%Y/%m/%d')))
	end_time   = int(time.mktime(time.strptime('2017/12/31', '%Y/%m/%d')))
	mydata['PayDate'] = pd.Series(np.random.randint(start_time,end_time,len(mydata))).map(lambda x: time.strftime("%Y-%m-%d", time.localtime(x)))
	mydata['interval'] = [(datetime.now() - pd.to_datetime(i,format ='%Y %m %d')).days for i in mydata['PayDate']]
	mydata = mydata.astype({'OrderID':'int64','UserID':'int64','PayAmount':'int64'})
	print('---------#######-----------')
	print(mydata.head())
	print('---------#######-----------')
	print(mydata.tail())
	print('…………………………………………………………………………')		
	print(mydata.dtypes)
	print('---------#######------------')

#按照用户ID聚合交易频次、交易总额及首次购买时间
mydata.set_index('UserID', inplace=True)
salesRFM = mydata.groupby(level = 0).agg({
	'PayAmount': np.sum,
	 'PayDate':  'count',
	 'interval':  np.min
	 }) 

# make the column names more meaningful
salesRFM.rename(columns={
	'PayAmount': 'Monetary',
	'PayDate': 'Frequency',
	'interval':'Recency'
	}, inplace=True)
salesRFM.head()

#均值划分
salesRFM  = salesRFM.assign(
  rankR   = pd.qcut(salesRFM['Recency'],  q = [0, .2, .4, .6,.8,1.] , labels = [5,4,3,2,1]),
  rankF   = pd.qcut(salesRFM['Frequency'],q = [0, .2, .4, .6,.8,1.] , labels = [1,2,3,4,5]),
  rankM   = pd.qcut(salesRFM['Monetary'] ,q = [0, .2, .4, .6,.8,1.] , labels = [1,2,3,4,5])
)
salesRFM['rankRMF'] =  100*salesRFM['rankR'] + 10*salesRFM['rankF'] + 1*salesRFM['rankM']


#特征缩放——0-1标准化
  
from sklearn import preprocessing
min_max_scaler = preprocessing.MinMaxScaler()

salesRFM1 = min_max_scaler.fit_transform(salesRFM.loc[:,['Recency','Frequency','Monetary']].values)
salesRFM  = salesRFM.assign(
	rankR1 = 1 - salesRFM1[:,0],
	rankF1 = salesRFM1[:,1],
	rankM1 = salesRFM1[:,2]
	)
salesRFM['rankRFM1'] = 0.5*salesRFM['rankR1'] + 0.3*salesRFM['rankF1'] + 0.2*salesRFM['rankM1']

#对R\F\M分类：
salesRFM = salesRFM.astype({'rankR':'int64','rankF':'int64','rankM':'int64'})
salesRFM = salesRFM.assign(
  R_S = salesRFM['rankR'].map(lambda x: 2 if x > salesRFM['rankR'].mean() else 1),
  F_S = salesRFM['rankF'].map(lambda x: 2 if x > salesRFM['rankF'].mean() else 1), 
  M_S = salesRFM['rankM'].map(lambda x: 2 if x > salesRFM['rankM'].mean() else 1)   
 )

#客户类型归类：
salesRFM['Custom'] = np.NaN
salesRFM.loc[(salesRFM['R_S'] == 2) & (salesRFM['F_S'] == 2) & (salesRFM['M_S'] == 2),'Custom']  = '高价值客户'
salesRFM.loc[(salesRFM['R_S'] == 1) & (salesRFM['F_S'] == 2) & (salesRFM['M_S'] == 2),'Custom']  = '重点保持客户' 
salesRFM.loc[(salesRFM['R_S'] == 2) & (salesRFM['F_S'] == 1) & (salesRFM['M_S'] == 2),'Custom']  = '重点发展客户' 
salesRFM.loc[(salesRFM['R_S'] == 1) & (salesRFM['F_S'] == 1) & (salesRFM['M_S'] == 2),'Custom']  = '重点挽留客户' 
salesRFM.loc[(salesRFM['R_S'] == 2) & (salesRFM['F_S'] == 2) & (salesRFM['M_S'] == 1),'Custom']  = '重点保护客户'  
salesRFM.loc[(salesRFM['R_S'] == 1) & (salesRFM['F_S'] == 2) & (salesRFM['M_S'] == 1),'Custom']  = '一般保护客户'  
salesRFM.loc[(salesRFM['R_S'] == 2) & (salesRFM['F_S'] == 1) & (salesRFM['M_S'] == 1),'Custom']  = '一般发展客户'    
salesRFM.loc[(salesRFM['R_S'] == 1) & (salesRFM['F_S'] == 1) & (salesRFM['M_S'] == 1),'Custom']  = '潜在客户'    

