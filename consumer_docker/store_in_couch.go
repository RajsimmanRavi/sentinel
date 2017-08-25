package main

import (
    "fmt"
    //"strconv"
    "strings"
    "net/http"
    "time"
    "io/ioutil"
    "github.com/buger/jsonparser"
)

//check() and check_rest_api() is in main.go 

func rest_api(url string, req_type string, body string) ([]byte, string) {

    //Create the HTTP client to send the request
    client := &http.Client{
        Timeout: 2 * time.Second, // Cause I don't have the patience
    }

    body_doc := strings.NewReader(body)
    req, _ := http.NewRequest(req_type, url, body_doc)
    req.Header.Set("Content-Type", "application/json")
    resp, err := client.Do(req)

    //Handle this error differently, cause you don't want to panic and shutdown
    check_rest_api(err)

    defer resp.Body.Close()

    // Read the response
    resp_body, _ := ioutil.ReadAll(resp.Body)

    return resp_body, resp.Status
}

//Function used to get all databases 
func get_all_dbs(couch_ip string) []byte{

    url := "http://"+couch_ip+":5984/_all_dbs"
    //don't care of the status
    data,_ := rest_api(url, "GET", "")

    return data
}


//Function to create a databse 
func create_db(couch_ip string, database string){

    url := "http://"+couch_ip+":5984/"+database
    data,status := rest_api(url, "PUT", "")

    fmt.Println(status+": "+string(data))
}


//Function to get uuid (unique identifier)
func get_uuid(couch_ip string) (string){

    url := "http://"+couch_ip+":5984/_uuids"
    data, _ := rest_api(url, "GET", "")

    //search for the key "uuids"
    uid_byte, _,_,_ := jsonparser.Get(data, "uuids")

    //convert it to string
    uid := string(uid_byte)

    //some parsing 
    ret_uuid := uid[1:len(uid)-1]

    return ret_uuid
}

//Function to insert data 
func insert_data(couch_ip string, database string, body string){

    //First, get an uuid for storing the document
    uuid := get_uuid(couch_ip)

    //remove the double quotes as well
    uuid = uuid[1:len(uuid)-1]

    url := "http://"+couch_ip+":5984/"+database+"/"+uuid 
    data,status := rest_api(url, "PUT", body)

    fmt.Println(status+": "+string(data))

}
