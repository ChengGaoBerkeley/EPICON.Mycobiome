
w.fst<-function (x){	#x is community matrix, each line is a community each row is a species
	y<-x/rowSums(x) #proportions
	num<-c();denom<-c()
	for (i in 1:dim(x)[[2]]){
		num[i]<-var(y[,i])
		denom[i]<-(mean(y[,i])*(1-mean(y[,i])))}
	out<-sum(num)/sum(denom)
	return(out)
	}


require(vegan)
site.fst<-function (x,groups){	#x is community matrix, each line is a community each row is a species, groups is a vector that gives the 'group' (treatment) for each line of x
	y<-x/rowSums(x) #proportions
	g.num<-(unique(groups))
	y1<-data.frame(groups,y)
	for (j in 1: length(g.num)){
		denom<-c()
		tmp<-subset(y1,groups==g.num[j])
		tmp<-subset(tmp,select=-c(groups))
		for (i in 1:dim(x)[[2]]){
			#num[i]<-var(y[,i])
			denom[i]<-(mean(tmp[,i])*(1-mean(tmp[,i])))}
			#denom[order(denom)]
			trans.x<-tmp/sqrt(sum(denom));#head(trans.x)
		if (j==1){
			new.d<-trans.x} else {
			new.d<-rbind(new.d,trans.x)}
	}
	tmp<-betadisper(dist(new.d),groups,type=c("centroid"))
	root.Fst<-tmp$distances
	out<-data.frame(groups,root.Fst)
	anova(tmp)
	return(out)
	}

