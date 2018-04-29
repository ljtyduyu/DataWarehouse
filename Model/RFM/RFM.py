
import numpy   as np
import pandas  as pd 
import savReaderWriter
import os

os.chdir('D:/R/File') 
mydata = savReaderWriter.SavReader("trade.sav", returnHeader= T)
  