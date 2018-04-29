## !/user/bin/env RStudio 1.1.423
## -*- coding: utf-8 -*-
## RFM Model

#客户细分模型
#客户响应模型
#客户价值模型
#客户促销模型

#* 最近一次消费(Recency)      
#* 消费频率(Frenquency)       
#* 消费金额(Monetary) 

####Code Part######

setwd('D:/R/File/')

library('magrittr')
library('dplyr')
library('scales')
library('ggplot2')
library("easyGgplot2")
library("Hmisc")  
library('foreign')
library('lubridate')

mydata <- spss.get("trade.sav",datevars = '交易日期',reencode = 'GBK') 
names(mydata) <- c('OrderID','UserID','PayDate','PayAmount') 

start_time <- as.POSIXct("2017/01/01", format="%Y/%m/%d") %>%  as.numeric()
end_time   <- as.POSIXct("2017/12/31", format="%Y/%m/%d") %>%  as.numeric()
set.seed(233333)
mydata$PayDate <- runif(nrow(mydata),start_time,end_time) %>% as.POSIXct(origin="1970-01-01") %>% as.Date()
mydata$interval <- difftime(max(mydata$PayDate),mydata$PayDate ,units="days") %>% round() %>% as.numeric()


#按照用户ID聚合交易频次、交易总额及首次购买时间
salesRFM <- mydata %>% group_by(UserID) %>% 
  summarise(
    Monetary  = sum(PayAmount),
    Frequency = n(),
    Recency   = min(interval)
    )

#均匀分箱得分
salesRFM <- mutate(
  salesRFM,
  rankR   = 6- cut(salesRFM$Recency,breaks = quantile(salesRFM$Recency,   probs = seq(0, 1, 0.2),names = FALSE),include.lowest = TRUE,labels=F),
  rankF   = cut(salesRFM$Frequency ,breaks = quantile(salesRFM$Frequency, probs = seq(0, 1, 0.2),names = FALSE),include.lowest = TRUE,labels=F),
  rankM   = cut(salesRFM$Monetary  ,breaks = quantile(salesRFM$Monetary,  probs = seq(0, 1, 0.2),names = FALSE),include.lowest = TRUE,labels=F),
  rankRMF = 100*rankR + 10*rankF + 1*rankM
)

#标准化得分
salesRFM <- mutate(
  salesRFM,
  rankR1 = 1 - rescale(salesRFM$Recency,to = c(0,1)),
  rankF1 = rescale(salesRFM$Frequency,to = c(0,1)),
  rankM1 = rescale(salesRFM$Monetary,to = c(0,1)),
  rankRMF1 = 0.5*rankR + 0.3*rankF + 0.2*rankM
)

#对R\F\M分类：
salesRFM <- within(salesRFM,{
  R_S = ifelse(rankR > mean(rankR),2,1)
  F_S = ifelse(rankF > mean(rankF),2,1)
  M_S = ifelse(rankM > mean(rankM),2,1)
})
  
#客户类型归类：
salesRFM <- within(salesRFM,{
  Custom = NA
  Custom[R_S == 2 & F_S == 2 & M_S == 2] = '高价值客户'
  Custom[R_S == 1 & F_S == 2 & M_S == 2] = '重点保持客户'
  Custom[R_S == 2 & F_S == 1 & M_S == 2] = '重点发展客户'  
  Custom[R_S == 1 & F_S == 1 & M_S == 2] = '重点挽留客户'
  Custom[R_S == 2 & F_S == 2 & M_S == 1] = '重点保护客户'
  Custom[R_S == 1 & F_S == 2 & M_S == 1] = '一般保护客户'
  Custom[R_S == 2 & F_S == 1 & M_S == 1] = '一般发展客户'
  Custom[R_S == 1 & F_S == 1 & M_S == 1] = '潜在客户'
})

#RFM分箱计数

ggplot(salesRFM,aes(rankF)) +
  geom_bar()+
  facet_grid(rankM~rankR) +
  theme_gray()

#RFM heatmap
heatmap_data <- salesRFM %>% group_by(rankF,rankR) %>% dplyr::summarize(M_mean = mean(Monetary))
ggplot(heatmap_data,aes(rankF,rankR,fill =M_mean )) +
  geom_tile() +
  scale_fill_distiller(palette = 'RdYlGn',direction = 1)

#RFM直方图 
p1 <- ggplot(salesRFM,aes(Recency)) +
      geom_histogram(bins = 10,fill = '#362D4C')
p2 <- ggplot(salesRFM,aes(Frequency)) +
  geom_histogram(bins = 10,fill = '#362D4C')  
p3 <- ggplot(salesRFM,aes(Monetary)) +
  geom_histogram(bins = 10,fill = '#362D4C')  
ggplot2.multiplot(p1,p2,p3, cols=3)

#RFM 两两交叉散点图
p1 <- ggplot(salesRFM,aes(Monetary,Recency)) +
  geom_point(shape = 21,fill = '#362D4C' ,colour = 'white',size = 2)
p2 <- ggplot(salesRFM,aes(Monetary,Frequency)) +
  geom_point(shape = 21,fill = '#362D4C' ,colour = 'white',size = 2)  
p3 <- ggplot(salesRFM,aes(Frequency,Recency)) +
  geom_point(shape = 21,fill = '#362D4C' ,colour = 'white',size = 2)  
ggplot2.multiplot(p1,p2,p3, cols=1)

#导出结果数据

write.csv(salesRFM,'salesRFM.csv')

