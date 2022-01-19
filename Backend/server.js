// const http = require('http');

// const server = http.createServer((request,response)=> {
//     console.log('workssss')
//     response.setHeader('Content-Type','text/html');
//     response.end('<h1>Hellooooo</h1>')
// })

// server.listen(3000);

const express = require('express');
const bodyParser = require('body-parser');
const knex = require('knex');

db = knex({
  client: 'pg',
  connection: {
    host : '127.0.0.1',
    port : 5432,
    user : 'pi',
    password : 'pi',
    database : 'saddb'
  }
});

db.select('*').from('steps').then(data=>{
    console.log(data);
});
db.select('*').from('activities').then(data=>{
    console.log(data);
});
db.select('*').from('location').then(data=>{
    console.log(data);
});
//db.select('*').from('weather').then(data=>{
//    console.log(data);
//});
//db.select('*').from('forecast').then(data=>{
//    console.log(data);
//});

const app = express();

app.use(express.json());
app.use(express.urlencoded({ extended: false }));

port = process.env.PORT || 3000;
app.get('/', (req,res)=> {
    res.send("getting root");
});

app.post('/', (req,res)=> {
    res.json('got data');
    //const {data} = req.body.steps;
    console.log(JSON.stringify(req.body, null, 2));
});


app.post('/location', (req,res)=> {
    //res.json('got data');
    const {id ,dateTime,latitude,longitude,addres,name} = req.body
    console.log(JSON.stringify(req.body, null, 2));
    db('location').insert({
        //time:moment(time, "YYYY-MM-DD HH:mm:ss"),
        time:dateTime,
        latitude:latitude,
        longitude:longitude,
        address:addres,
        name:name
    }).then( function (result) {
        res.json({ success: true, message: 'ok' });     
    });
});

app.post('/steps', (req,res)=> {
    //res.json('got data');
    const {id ,dateTime,steps} = req.body;
    console.log(JSON.stringify(req.body, null, 2));
    db('steps').insert({
        steps:steps,
        time:dateTime
    }).then( function (result) {
        res.json({ success: true, message: 'ok' });     
    });
});

app.post('/activity', (req,res)=> {
    //res.json('got data');
    const {id ,dateTime,certainty,activity} = req.body;
    console.log(JSON.stringify(req.body, null, 2));
    db('activities').insert({
        activity:activity,
        time:dateTime
    }).then( function (result) {
        res.json({ success: true, message: 'ok' });     
    });
});


app.post('/weather', (req,res)=> {
    //res.json('got data');
    const {id ,dt,temp,feelslike,uvi,clouds} = req.body.hourly;
    console.log(JSON.stringify(req.body.hourly, null, 2));
    for (var i = 0; i < 24; i++) {
        console.log(req.body.hourly[i].uvi)
      db('weather').insert({
        uvi:req.body.hourly[i].uvi,
        cloud:req.body.hourly[i].clouds,
        time:req.body.hourly[i].dt,
        condition:req.body.hourly[i].weather[0].main
        }).then(()=>{});
    }
    res.json({ success: true, message: 'ok' });
});


app.post('/forecast', (req,res)=> {
    //res.json('got data');
    const {id ,dt,temp,feelslike,uvi,clouds} = req.body.hourly;
    console.log(JSON.stringify(req.body.hourly, null, 2));
    for (var i = 0; i < 24; i++) {
        console.log(req.body.hourly[i].uvi)
      db('forecast').insert({
        uvi:req.body.hourly[i].uvi,
        cloud:req.body.hourly[i].clouds,
        time:req.body.hourly[i].dt,
        condition:req.body.hourly[i].weather[0].main
        }).then(()=>{});
    }
    res.json({ success: true, message: 'ok' });
});

app.post('/social', (req,res)=> {
    res.json('got data');
    //const {data} = req.body.steps;
    console.log(JSON.stringify(req.body, null, 2));
});


app.listen(3000)
