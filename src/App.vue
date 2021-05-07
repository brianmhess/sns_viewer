<template>
  <div id="app">
    <img alt="Amazon Simple Notification Service" src="./assets/SNS.png">
    <div class="message-list">
      <h4>Messages</h4>
      <hr>
      <div id="chat-messages" class="message-group" v-chat-scroll="{smooth: true}">
        <div class="message" v-for="(message, index) in reverseSnsmsgs" :key="index">
          <p style="font-size:18px" align="left">
            {{ message.message }}
          </p>
          <div class="clearfix">
            <small class="text-muted float-right">{{ message.timestamp }}</small>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { bus } from '@/main'
let mqttClient

export default {
  name: 'App',
  components: {
  },
  data() {
    return {
      snsmsgs: Array,
      reverseSnsmsgs: Array,
      lastMessage: ""
    }
  },
  created() {
    bus.$on('messageReceived', async (msg) => {
      console.log('messageReceived: ', msg)
      this.snsmsgs.push(msg)
      this.reverseSnsmsgs.unshift(msg)
      this.lastMessage = msg
    })
  },
  mounted() {
    this.snsmsgs = [];
    this.reverseSnsmsgs = [];
    this.mountIOT();
    console.log("Mounted...")
  },
  methods: {
    subscribe (topic) {
      console.log('IoT subcribing to ', topic)
      mqttClient.subscribe(topic)
    },
    addmsg(msg) {
      this.snsmsgs.push(msg);
      this.reverseSnsmsgs.unshift(msg);
    },
    mountIOT () {
      const AWS = require('aws-sdk')
      const AWSIoTData = require('aws-iot-device-sdk')
      let errorCount = 0
      const AWSConfiguration = {
        poolId: process.env.VUE_APP_POOLID,
        host: process.env.VUE_APP_IOTENDPOINT,
        region: process.env.VUE_APP_AWSREGION
      }
      var notificationTopic = process.env.VUE_APP_IOTTOPIC
      console.log('poolId: ', AWSConfiguration.poolId)
      console.log('host: ', AWSConfiguration.host)
      console.log('region: ', AWSConfiguration.region)
      console.log('notificationTopic: ', notificationTopic)
      var clientId = 'happyPath-' + (Math.floor((Math.random() * 100000) + 1))
      AWS.config.region = AWSConfiguration.region
      AWS.config.credentials = new AWS.CognitoIdentityCredentials({
        IdentityPoolId: AWSConfiguration.poolId
      })
      console.log('IoT created')
      mqttClient = AWSIoTData.device({
        region: AWS.config.region,
        host: AWSConfiguration.host,
        clientId: clientId,
        protocol: 'wss',
        maximumReconnectTimeMs: 8000,
        debug: false,
        accessKeyId: '',
        secretKey: '',
        sessionToken: ''
      })
      console.log('mqttClient created')
      const cognitoIdentity = new AWS.CognitoIdentity()
      const getCreds = function () {
        AWS.config.credentials.get(function (err, data) {
          if (!err) {
            console.log('retrieved identity: ' + AWS.config.credentials.identityId, data)
            const params = {
              IdentityId: AWS.config.credentials.identityId
            }
            cognitoIdentity.getCredentialsForIdentity(params, function (err, data) {
              if (!err) {
                mqttClient.updateWebSocketCredentials(data.Credentials.AccessKeyId,
                  data.Credentials.SecretKey,
                  data.Credentials.SessionToken)
              } else {
                console.log('error retrieving credentials: ' + err)
              }
            })
          } else {
            console.log('error retrieving identity:' + err)
          }
        })
      }
      console.log('getCreds done')

      mqttClient.on('connect', function () {
        console.log('mqttClient connected')
        mqttClient.subscribe(notificationTopic)
      })

      mqttClient.on('error', function (err) {
        if (errorCount > 0) {
          console.log('mqttClient error:', err)
        }
        errorCount++
        getCreds()
      })

      mqttClient.on('message', function (topic, payload) {
        const msg = JSON.parse(payload.toString());
        console.log('IoT msg: ', msg);
        bus.$emit('messageReceived', msg)
      })
    }
  }
}
</script>

<style>
#app {
  font-family: Avenir, Helvetica, Arial, sans-serif;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
  text-align: center;
  color: #2c3e50;
  margin-top: 60px;
}

.message-list {
  margin-bottom: 15px;
  padding-right: 15px;
  padding-left: 15px;
}
.message-group {
  height: 65vh !important;
  overflow-y: scroll;
}
.message {
  border: 1px solid lightblue;
  border-radius: 4px;
  padding: 10px;
  margin-bottom: 15px;
}
.message-title {
  font-size: 1rem;
  display:inline;
}
.message-text {
  color: gray;
  margin-bottom: 0;
}
.user-typing {
  height: 1rem;
}

</style>
