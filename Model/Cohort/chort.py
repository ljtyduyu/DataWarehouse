import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import matplotlib as mpl
import os

pd.set_option('max_columns', 50)
mpl.rcParams['lines.linewidth'] = 2
%matplotlib inline

os.chdir("D:/R/File/")
df = pd.read_excel('relay-foods.xlsx', sheet='Purchase Data')
df.head()

#2. 确定 OrderDate的月份，根据 OrderDate 分群
df['OrderPeriod'] = df.OrderDate.apply(lambda x: x.strftime('%Y-%m'))

# goupby(level=0): level 是index的level， 对于multiIndex， 可用level=0或1指定根据那个index来group
df.set_index('UserId', inplace=True)
df['CohortGroup'] = df.groupby(level=0)['OrderDate'].min().apply(lambda x: x.strftime('%Y-%m'))
df.reset_index(inplace=True)

#3. 计算每个CohortGroup在各个OrderPeriod的用户量

# pd.Series.nunique --> Return number of unique elements in the object.

grouped = df.groupby(['CohortGroup', 'OrderPeriod'])

# count the unique users, orders, and total revenue per Group + Period
cohorts = grouped.agg({'UserId': pd.Series.nunique,
                       'OrderId': pd.Series.nunique,
                       'TotalCharges': np.sum})

# make the column names more meaningful
cohorts.rename(columns={'UserId': 'TotalUsers',
                        'OrderId': 'TotalOrders'}, inplace=True)
cohorts.head()

#4. 标记每个CohortGroup的Cohort时期

def cohort_period(df):
    df['CohortPeriod'] = np.arange(len(df)) + 1
    return df

cohorts = cohorts.groupby(level=0).apply(cohort_period)
cohorts.head()

[(k,v) for k,v in cohorts.head(5).groupby(level=0)]


#5. 计算每个CohortGroup在第一个CohortPeriod的用户数量

cohorts = cohorts.reset_index().set_index(['CohortGroup', 'CohortPeriod'])

cohort_group_size = cohorts['TotalUsers'].groupby(level=0).first()
cohort_group_size


#6. 计算每个CohortPeriod的留存率

user_retention = cohorts['TotalUsers'].unstack(0).divide(cohort_group_size, axis=1)
user_retention.head()

#留存率曲线

user_retention[['2009-01', '2009-05','2009-08']].plot(figsize=(11,6), color=['#A60628', '#EA4335', '#4285f4'])
plt.title("Cohorts: User Retention")
plt.xticks(np.arange(1, len(user_retention)+1, 1))
plt.xlim(1, len(user_retention))
plt.ylabel('% of Cohort Purchasing', fontsize=16)

#留存率热力图

import seaborn as sns
sns.set(style='white')

plt.figure(figsize=(16, 8))
plt.title('Cohorts: User Retetion', fontsize=14)
sns.heatmap(user_retention.T, 
            mask=user_retention.T.isnull(), 
            annot=True, 
            fmt='.0%',
            cmap="YlGnBu")




