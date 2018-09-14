var output = require(__dirname + "/output.js"),
	api = require(__dirname + "/../api"),
	errorcodes = api.errorcodes;

module.exports = {
	
	sectionCode: 1,
	
	start: function(payload, request, response) {
		api.init.start(payload, function(error, errorcode) {
			if(error) {
				return output.terminate(payload, response, errorcode, error);
			}
			var returnObj = {
				appsession: payload.appsession,
				appname: payload.appname,
				tos: payload.tos,
				privacy: payload.privacy
			}
			var r = output.end(payload, response, returnObj, errorcodes.NoError);
		});
	}
}