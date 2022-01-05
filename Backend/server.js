// const http = require('http');

// const server = http.createServer((request,response)=> {
//     console.log('workssss')
//     response.setHeader('Content-Type','text/html');
//     response.end('<h1>Hellooooo</h1>')
// })

// server.listen(3000);

const express = require('express');
const bodyParser = require('body-parser')

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
    res.json('got data');
    //const {data} = req.body.steps;
    console.log(JSON.stringify(req.body, null, 2));
});

app.post('/steps', (req,res)=> {
    res.json('got data');
    //const {data} = req.body.steps;
    console.log(JSON.stringify(req.body, null, 2));
});

app.post('/social', (req,res)=> {
    res.json('got data');
    //const {data} = req.body.steps;
    console.log(JSON.stringify(req.body, null, 2));
});

app.listen(3000)