#Need
library(xts)
library(zoo)
library(quantmod)
##This library stuffs up tab completes in RStudio
#library(debug)

#Set working directory
setwd("~/Documents/R/StrategyTester")


#Get All ordinaries data from yahoo and write to file - when uncommented
#getSymbols('^AORD',src='yahoo',from="2007-01-01",to=(Sys.Date()))
#write.table(AORD,"AORD.csv", sep=",",row.names=index(AORD))
#remove(AORD)

#################################################################
################ Part 1: Data Import ############################
#################################################################


#Getting Data
AORD = as.xts(as.zoo(read.table("Data/AORD.csv",header=T,sep=",")))

#Creating EMA using quantmod
chartData = AORD['2008-02::2008-08']
chartSeries(chartData,TA=NULL, theme="white")
EMA1=addEMA(n=10,col=2)
EMA1Vals=EMA1@TA.values
EMA2=addEMA(n=20)
EMA2Vals=EMA2@TA.values
#Adding MA to Data object
Series1 = as.xts(zoo(EMA1Vals,order.by=index(chartData)));colnames(Series1)="MAs"
Series2 = as.xts(zoo(EMA2Vals,order.by=index(chartData)));colnames(Series2)="MAl"
chartData = cbind.xts(chartData,Series1,Series2 )
head(chartData,2)


#################################################################
################ Part 2: Market Data, Trade, Portfolio Classes ##
#################################################################

#Load Classes up to StrategyTester
source('R/PortfolioClasses.R')

MD = MarketData(chartData) #Create Market Data
#Create trades and value against a slice of Market Data
T1 = Trade("Cash","Cash",100) #Create Trade Objects
T2 = Trade("AORD","Eq",100)
MDSlice = MarketDataSlice(MD,1)#Create MarketData time slice.Port1=Portfolio("Port1",c(T1,T2)) #Create Portfolio Object
Value(T1,MDSlice)
Value(T2,MDSlice)

#Put trades in a Portfolio and Value for a given slice of time
#PortfolioSlice constructor
TradeList = list(T1,T2)
Port1=Portfolio("Port1",TradeList)
print(Port1) #Overloaded print for Porfolio
time = 1 #Pice time
PortfolioSlice = PortfolioSlice(MD,Port1,time) #Create Portfolio slice
Price(PortfolioSlice) #Query slice for Price
Value(PortfolioSlice) #Query slice for Value
#Can add more query methods when necessary - e.g. Delta's, risk reports, etc

#################################################################
################ Part 3: Running Strategy #######################
#################################################################

#TradeStrategy Example
source('R/TradeStrategyClasses.R')
#Initialise empty cash portfolio - strategy will trade accordingly
#I assume zero interest rate by setting price of cash =1. 
#Can change by having P_cash grow by interest rate - set up an ir profile
Cash=Trade(Name="Cash",Type="Cash",0)
Port_MAtest = Portfolio("Port_MAtest",list(Cash))
#Initialise strategy
TS1=TradeStrategy(Port_MAtest,MD,21)
#Check vals exist
Time=TS1$CurrentTime
TS1$MarketData$Data[(Time-1):Time,]

#The Trade Strategy class has some useful members
#- updSignal, this generates trade signal "buy", "hold", "sell"
	updSig(TS1) #Should be sell
# -updatePortfolio, this updates portfolio by making trades if signal requires
	print(TS1$Portfolio) #only cash in Portfolio
	TS1$CurrentTime #Current time index
	TS1=updatePortfolio(TS1)
	print(TS1$Portfolio) #now two trades as signal was sell
	TS1$CurrentTime #Current time index

	
# -runStrategy, loops updatePortfolio over Market Data and collects results
#Initialise strategy back to time 21 and only cash in Port
TS1=TradeStrategy(Port_MAtest,MD,21)
TS1 = runStrategy(TS1)
head(TS1$Results,5)


#################################################################
################ Part 4: Displaying Results #####################
#################################################################



#Find where Trade Events occured
TradeEvents = which(TS1$Results[,"Signal"] != "hold")
TD = as.Date(TS1$Results$Time)[TradeEvents]
TradeDate = index(TS1$MarketData$Data)[TradeEvents]
TradeSigs= TS1$Results[TradeEvents,"Signal"]

#Create Data for Plots
ResZoo = zoo(TS1$Results$Value,order.by=as.Date(TS1$Results$Time))
ResZoo = merge(ResZoo,chartData)

#Create info for axis labels and Trade Dates
domain=index(ResZoo)
TradeDatesZooPlot = domain[which(domain%in%TradeDate)]
numberTix = 20
spacing=floor(length(domain)/numberTix)
marks = domain[seq(1,length(domain),spacing)]
labs= format(marks,"%d%b%y")
ResZoo[20:22,c(5,8,9)]
colnames(ResZoo)
#x11() #opens graphics device on linux
#Plot 
split.screen(figs = c(2,1))
screen(1)
plot.zoo(ResZoo[-1,c(5,8,9)],ylim=c(3000,6200),screens=c(1,1,1),col=c("black","green","blue"),xaxt='n',xlab="Date",ylab="Price And TA")
axis(side=1,at=marks,labels=labs)
abline(v=TD,col="red")	
screen(2)
plot.zoo(ResZoo[-1,1],ylim=c(-20000,210000),screens=c(1),col=c("blue"),xaxt='n',xlab="Date",ylab="Portfolio Value")
abline(v=TD,col="red")	
abline(h=0,col="black")
axis(side=1,at=marks,labels=labs)

#dev.off()
#graphics.off()
