#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import time
import numpy   as np
import pandas  as pd 
import os
from scrapy.exceptions import DropItem


np.random.seed(233333)
os.chdir('D:/R/File') 

mydata = pd.read_excel("AHP_example.xls")

def Weight(data):
	if data.shape[0] == data.shape[1] - 1 and data.iloc[:,0].dtype == 'object':
		data = data.iloc[:,1:]
		data.index = data.columns	
	elif data.shape[0] == data.shape[1]:
		data.index = data.columns
	else:
		raise DropItem("please recheck your data structure , you must keep a equal num of the row and col")
	weigth_matrix  = data.loc[:,].values
	weight_vector  = weigth_matrix/np.sum(data.loc[:,].values,0)
	sum_vector_col = weight_vector.sum(axis = 1)
	return {
	"weigth_matrix":weigth_matrix,
	"weight_vector":sum_vector_col/sum_vector_col.sum()
	}

Weight(mydata)["weigth_matrix"]
Weight(mydata)["weight_vector"]

def AW_Weight(data):
	if data.shape[0] == data.shape[1] - 1 and data.iloc[:,0].dtype == 'object':
		data = data.iloc[:,1:]
		data.index = data.columns	
	elif data.shape[0] == data.shape[1]:
		data.index = data.columns
	else:
		raise DropItem("please recheck your data structure , you must keep a equal num of the row and col")
	AW_Vector = np.dot(data.values,Weight(mydata)["weight_vector"])
	λ = (AW_Vector/Weight(mydata)["weight_vector"]).sum()/len(AW_Vector)
	return dict(
		AW_Vector = AW_Vector,
		AW_Vector_w = AW_Vector/Weight(mydata)["weight_vector"],
		λ = λ
		)

AW_Weight(mydata)["AW_Vector"]
AW_Weight(mydata)["AW_Vector_w"]
AW_Weight(mydata)["λ"]

def Consist_Test(λ,n):
	RI_refer =  [0,0,0.52,0.89,1.12,1.26,1.36,1.41,1.46,1.49,1.52,1.54]
	CI = (λ - n)/(n - 1)
	CR = CI/(RI_refer[n-1])
	if (CR <= 0.1):
		print(" 通过一致性检验！")
		print(" Wi: ", np.round(CR,4))
	else:
		print(" 请调整判断矩阵！","\n")
	return np.round(CR,4)





