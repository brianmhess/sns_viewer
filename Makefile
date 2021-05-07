#VUE_APP_POOLID?="CognitoIdentityPoolId"
#VUE_APP_IOTENDPOINT?="AWSIOTENDPOINT-ats.iot.us-east-2.amazonaws.com"
#VUE_APP_AWSREGION?="AWSREGION"
#VUE_APP_IOTTOPIC?="IOTTopicNameToListenFor"

#VUE_ENV=VUE_APP_POOLID=${VUE_APP_POOLID} VUE_APP_IOTENDPOINT=${VUE_APP_IOTENDPOINT} VUE_APP_AWSREGION=${VUE_APP_AWSREGION} VUE_APP_IOTTOPIC=${VUE_APP_IOTTOPIC}

install:
	npm install

clean:
	${RM} sns_viewer.zip

serve:
	npm run serve

build:
	npm run build

serve_dist:
	serve -s dist

tozip := LICENSE babel.config.js package.json package-lock.json $(wildcard public/*) $(wildcard src/*) $(wildcard src/*/*)
sns_viewer.zip: $(tozip)
	${RM} sns_viewer.zip
	zip sns_viewer.zip $(tozip)
