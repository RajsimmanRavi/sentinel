package main

import (
    "fmt"
    "os"
    "os/signal"
    "syscall"
    "strings"
)

//Generic function to check for any errors
func check(e error) {
	if e != nil {
		panic(e)
		return
	}
}

//This is for handling errors for REST APIs. You know, for not panicking!
func check_rest_api(e error){
    if e != nil {
        fmt.Println(e.Error())
    }
}

func main() {

    topic := os.Getenv("TOPIC")
    kafka_broker := os.Getenv("KAFKA_BROKER")
    couch_ip := os.Getenv("COUCH_IP")
    db_name := os.Getenv("DB_NAME")

    // Capture any signals before exiting
	c := make(chan os.Signal, 1)
	signal.Notify(c,
		os.Interrupt,
		syscall.SIGHUP,
		syscall.SIGINT,
		syscall.SIGTERM,
		syscall.SIGQUIT)

    go func() {
		<-c
        fmt.Println("Interrupt is detected")
		os.Exit(1)
	}()

    databases := get_all_dbs(couch_ip)

    //If database not found, then create one.
    if !(strings.Contains(string(databases), db_name)){
        create_db(couch_ip, db_name)
    }

    //Call consumer to start streaming and storing data
    consumer(topic, kafka_broker, couch_ip, db_name)
}
