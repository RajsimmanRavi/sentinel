FROM golang:latest 
RUN go get github.com/buger/jsonparser
RUN go get github.com/Shopify/sarama
RUN mkdir /consumer
ADD . /consumer/ 
WORKDIR /consumer 
RUN go build -o main . 
CMD ["/consumer/main"]

