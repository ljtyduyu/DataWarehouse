library('xlsx')
library('ggplot2')
library('dplyr')
library('magrittr')
library('tidyr')
library('reshape2')

setwd("D:/R/File/")
df <- read.xlsx('relay-foods.xlsx', sheetName = 'Purchase Data') 

df$OrderPeriod = format(df$OrderDate,'%Y-%m')
CohortGroup = df %>% group_by(UserId) %>% 
              summarize( CohortGroup = min(OrderDate)) 

CohortGroup$CohortGroup <-  CohortGroup$CohortGroup %>% format('%Y-%m')

df <- df %>% left_join(CohortGroup,by = 'UserId')

chorts <- df %>% group_by(CohortGroup,OrderPeriod) %>% 
           summarize(
           	UserId  = n_distinct(UserId),
           	OrderId = n_distinct(OrderId),
           	TotalCharges = sum(TotalCharges)
           	) %>% rename(TotalUsers= UserId , TotalOrders = OrderId)

chorts <- chorts %>% 
              arrange(CohortGroup,OrderPeriod) %>% 
              group_by(CohortGroup) %>% 
              mutate( CohortPeriod =row_number())

cohort_group_size <- chorts %>% 
             filter(CohortPeriod == 1) %>% 
             select(CohortGroup,OrderPeriod,TotalUsers)
user_retention <- chorts %>% 
             select(CohortGroup,CohortPeriod,TotalUsers) %>% 
             spread(CohortGroup,TotalUsers) 

user_retention[,-1] <- user_retention[,-1] %>% t() %>% `/`(cohort_group_size$TotalUsers) %>% t() %>% as.data.frame()



user_retention1 <- user_retention %>% select(1:5) %>% 
            melt( 
            	id.vars = 'CohortPeriod', 
            	variable.name = 'CohortGroup', 
            	value.name = 'TotalUsers'
            	)

ggplot(user_retention1,aes(CohortPeriod,TotalUsers)) +
     geom_line(aes(group = CohortGroup,colour = CohortGroup)) +
     scale_x_continuous(breaks = 1:15) +
     scale_colour_brewer(type = 'div')

user_retentionT <- t(user_retention) %>% .[2:nrow(.),]  %>% as.data.frame
user_retentionT$CohortPeriod <- row.names(user_retentionT)
row.names(user_retentionT) <- NULL
user_retentionT <- user_retentionT[,c(16,1:15)]

user_retentionT1 <- user_retentionT %>% 
            melt( 
            	id.vars = 'CohortPeriod', 
            	variable.name = 'CohortGroup', 
            	value.name = 'TotalUsers'
            	)

library("Cairo")
library("showtext")

font_add("myfont","msyh.ttc")
CairoPNG("C:/Users/RAINDU/Desktop/emoji1.png",1000,750)
showtext_begin()
ggplot(user_retentionT1 ,aes(CohortGroup,CohortPeriod,fill=TotalUsers))+
  geom_tile(colour='white') +
  geom_text(aes(label = ifelse(TotalUsers != 0,paste0(round(100*TotalUsers,2),'%'),'')),colour = 'blue') +
  scale_fill_gradient2(limits=c(0,.55),low="#00887D", mid ='yellow', high="orange",midpoint = median(user_retentionT1$TotalUsers, na.rm =TRUE),na.value = "grey90") +
  scale_y_discrete(limits = rev(unique(user_retentionT1$CohortPeriod))) +
  scale_x_discrete(position = "top")+
  labs(title="XXX产品Chort留存分析",subtitle="XXX产品在2019年1月至2010年三月中间的留存率趋势")+
  theme(
    text = element_text(family = 'myfont',size = 15),
    rect = element_blank()
    )
showtext_end()
dev.off()


