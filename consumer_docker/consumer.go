package main

import (
    "fmt"
    "github.com/Shopify/sarama"
)

//Reference: https://github.com/tcnksm-sample/sarama/blob/master/consumer/main.go 
//Reference: https://github.com/mycodesmells/kafka-to-go/blob/master/kafka/consumer.go
//Reference: http://mycodesmells.com/post/kafka-to-go

func consumer(topic string, kafka_broker string, couch_ip string, db_name string) {

	config := sarama.NewConfig()
	config.Consumer.Return.Errors = true

	// Specify brokers address. This is default one
	brokers := []string{kafka_broker}

	// Create new consumer
	master, err := sarama.NewConsumer(brokers, config)
    check(err)

    defer master.Close()

	// How to decide partition, is it fixed value...?
	consumer, err := master.ConsumePartition(topic, 0, sarama.OffsetOldest)
	check(err)

    for {
	    select {
		    case err := <-consumer.Errors():
				fmt.Println(err)
			case msg := <-consumer.Messages():
               //store it in couchdb. Function is in store_in_couch.go
               insert_data(couch_ip, db_name, string(msg.Value))
        }
	}
}
