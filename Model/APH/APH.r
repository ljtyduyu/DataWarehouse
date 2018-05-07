## !/user/bin/env RStudio 1.1.423
## -*- coding: utf-8 -*-
## APH 模型

rm(list = ls())
gc()
setwd("D:/R/File/")

library("readxl")
library("dplyr")
library("magrittr")

#  建立层次结构模型
#  ——>构造判断矩阵
#  ——>层次单排序
#  ——>一致性检验
#  ——>层次总排序


mydata <- read_excel("AHP_example.xls")

#### Deme ####
mydata[7,-1] <- mydata[,-1]  %>% apply(2,sum)
mydata[7,1]  <- '列和'

mydata1 <- apply(mydata[,-1],1,function(x) x/mydata[7,-1]) %>% 
           do.call(rbind,.) %>% 
           cbind(mydata[,1],.) %>% 
           mutate(row_sum = apply(.[,-1],1,sum))

scale_w <- mydata1[-7,8]/mydata1[7,8] 

row_sum <- apply(mydata1[,-1],1,sum)
names(row_sum) <- mydata[1:6,1]$A

AW <- mydata[-7,-1] %>% as.matrix()  %*% scale_w 
`AW/w` <- AW/scale_w 
`sum_aw/w` <- sum(`AW/w`)
Tw <- `sum_aw/w`/6

RI_value <- data.frame(
	scale = 1:12,
	value = c(0,0,0.52,0.89,1.12,1.26,1.36,1.41,1.46,1.49,1.52,1.54)
	)

CI <- (Tw - 6)/(6 -1)
CR <- CI/RI_value[RI_value$scale ==6,'value']

#### PRO ####

#1、判断矩阵归一化：

Weigth_fun <- function(data){
  if(class(data) == 'matrix'){
      data = data     
  } else {
    if ( class(data) == 'data.frame' & nrow(data) == ncol(data) - 1 & is.character(data[,1,drop = TRUE])){
      data = as.matrix(data[,-1])
    } else if (class(data) == 'data.frame' & nrow(data) == ncol(data)) {
      data = as.matrix(data)
    } else {
      stop('please recheck your data structure , you must keep a equal num of the row and col')
    }    
  }
  sum_vector_row    =  apply(data,2,sum)
  decide_matrix     =  apply(data,1,function(x) x/sum_vector_row) 
  weigth_vector     =  apply(decide_matrix,2,sum)
  result = list(decide_matrix = decide_matrix, weigth_vector  = weigth_vector/sum(weigth_vector ))
  return(result)
}

Weigth_fun(data_C)

#2、输出特征向量λ
AW_Weight <- function(data){
  if(class(data) == 'matrix'){
    data = data     
  } else {
    if ( class(data) == 'data.frame' & nrow(data) == ncol(data) - 1 & is.character(data[,1,drop = TRUE])){
      data = as.matrix(data[,-1])
    } else if (class(data) == 'data.frame' & nrow(data) == ncol(data)) {
      data = as.matrix(data)
    } else {
      stop('please recheck your data structure , you must keep a equal num of the row and col')
    }    
  }
  AW_Vector = data %*% Weigth_fun(data)$weigth_vector
  λ = sum(AW_Vector/Weigth_fun(data)$weigth_vector)/length(AW_Vector)
  result = list(
    AW_Vector = AW_Vector,
    `∑AW/W`   = AW_Vector/Weigth_fun(data)$weigth_vector,
    λ         =  λ
  )
  return(result)
}
AW_Weight(data_C)

#3、一致性检验：

Consist_Test <- function(λ,n){
  RI_refer =  c(0,0,0.52,0.89,1.12,1.26,1.36,1.41,1.46,1.49,1.52,1.54)
  CI = (λ - n)/(n - 1)
  CR = CI/(RI_refer[n])
  if (CR <= .1){
    cat(" 通过一致性检验！",sep = "\n")
    cat(" Wi: ", round(CR,4), "\n")
  } else {
    cat(" 请调整判断矩阵！","\n")
  }
  return(CR)
}

Consist_Test(AW_Weight(data_C)$λ,5)








