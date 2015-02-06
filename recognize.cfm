<cfscript>
	include 'tags.cfm';
	theFile = expandPath('./images/recognizedFaces/face-0-20150128232309.jpg');
	objBinaryData = fileReadBinary(theFile);
	imageBase64 = ToBase64(objBinaryData);
	cfhttp(method='post', url='http://rekognition.com/func/api/') {
		cfhttpParam(type='formfield', name='api_key', value=variables.apiData['api_key']);
		cfhttpParam(type='formfield', name='api_secret', value=variables.apiData['api_secret']);
		cfhttpParam(type='formfield', name='jobs', value=variables.apiData['jobs']);
		cfhttpParam(type='formfield', name='name_space', value=variables.apiData['name_space']);
		cfhttpParam(type='formfield', name='user_id', value=variables.apiData['user_id']);
		cfhttpParam(type='formfield', name='base64', value='#imageBase64#');
	}
	returnStruct = deserializeJson(cfhttp.fileContent);
	faceTag = returnStruct.face_detection[1].matches[1].tag;
	accuracy = returnStruct.face_detection[1].matches[1].score*100;
</cfscript>
