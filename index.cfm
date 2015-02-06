<cfscript>
	include 'tags.cfm';
	
	//Image upload form
	if(!isDefined('form.imageFile')) {
		writeOutput('
			<h1>Face Detection Image Upload</h1>
			<form name="imageForm" method="post" enctype="multipart/form-data">
				<input type="file" name="imageFile"><br /><br />
				<input type="submit" name="Upload">
			</form>
		');
	} else {
		//Upload and load base image
		imageMetadata = FileUpload(expandPath('./images'), 'imageFile', 'image/jpeg', 'makeUnique'); 
		image = imageRead(expandPath('images/' & imageMetadata.clientFile));
		
		//Facial detection
		Detector = createObject('java', 'jviolajones.Detector').init(expandPath('haarcascade_frontalface_alt.xml'));
		results = Detector.getFaces(
			imageGetBufferedImage(image), //file : the image to work on 
			javaCast('float',2), //baseScale : The initial ratio between the window size and the Haar classifier size (default 2). 
			javaCast('float',1.25), //scale_inc The scale increment of the window size, at each step (default 1.25). 
			javaCast('float',.05), //increment The shift of the window at each sub-step, in terms of percentage of the window size. 
			javaCast('int',2), //min_neighbors : The minimum numbers of similar rectangles needed for the region to be considered as a face (avoid noise) 
			javaCast('boolean',true) //doCannyPruning : enable Canny Pruning to pre-detect regions unlikely to contain faces, in order to speed up the execution. 
		);

		writeOutput('From this Image:<br /><img src="images/#imageMetadata.clientFile#" width="33%" /><br /><br />');
		
		//Do stuff with each face
		numberOfFaces = 0;
		faceImageList = [];
		for(i=1; i <= arrayLen(results); i++) {
			numberOfFaces++;
			thisFaceData = {};
			faceImage = imageCopy(image, results[i].x, results[i].y, results[i].width, results[i].height);
			faceImageName = 'face-#numberOfFaces#-#dateFormat(now(),'yyyymmdd')##timeFormat(now(),'HHmmss')#.jpg';
			imageWrite(faceImage, expandPath('images/recognizedFaces/#faceImageName#'));
			thisFaceData.url = 'images/recognizedFaces/#faceImageName#';
			thisFaceData.path = expandPath('images/recognizedFaces/#faceImageName#');
			
			//API call to facial recognition service
			objBinaryData = fileReadBinary(thisFaceData.path);
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
			if(arrayLen(returnStruct.face_detection) && arrayLen(returnStruct.face_detection[1].matches)) {
				thisFaceData.tag = returnStruct.face_detection[1].matches[1].tag;
				thisFaceData.accuracy = returnStruct.face_detection[1].matches[1].score*100;
			} else {
				thisFaceData.tag = 'not-a-person';
				thisFaceData.accuracy = 0;
			}

			arrayAppend(faceImageList, thisFaceData);
			if(thisFaceData.accuracy >= 70) {
				writeOutput('#variables.tags[thisFaceData.tag].name#<br /><img src="images/recognizedFaces/#faceImageName#" height="120" /><br /><br />');
			}
		}
		writeOutput('<br /><a href="">Back</a><br />');
	}
</cfscript>
