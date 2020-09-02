import QtQuick 2.9
import Ubuntu.Components 1.3
import Ubuntu.OnlineAccounts.Plugin 1.0

OAuthMain {
    creationComponent: Column {
        id: wrapper
        signal finished

        anchors.fill: parent
        spacing: units.gu(2)

        Label {
            anchors { left: parent.left; right: parent.right; margins: units.gu(1) }
            wrapMode: Text.Wrap
            text: i18n.dtr("account-plugins", "Google requires users to authenticate via the system Browser. Press the button below to start the authentication process.")
        }

        Button {
            anchors { left: parent.left; right: parent.right; margins: units.gu(4) }
            text: i18n.dtr("account-plugins", "Open Morph Browser")
            color: theme.palette.normal.positive
            onClicked: oauth.authenticate()
        }

        Button {
            anchors { left: parent.left; right: parent.right; margins: units.gu(4) }
            text: i18n.dtr("account-plugins", "Cancel")
            onClicked: wrapper.finished()
        }

        OAuth {
            id: oauth
            anchors { left: parent.left; right: parent.right; top: undefined; bottom:undefined }
            visible: false
            authenticationParameters: {
                "AuthPath": "o/oauth2/auth?access_type=offline&approval_prompt=force",
                "RedirectUri": loopbackServer.callbackUrl.toString()
            }
            requestHandler: browserRequestHandler
            onFinished: wrapper.finished()

            function getUserName(reply, callback) {
                console.log("Access token: " + reply.AccessToken)
                var http = new XMLHttpRequest()
                var url = "https://www.googleapis.com/oauth2/v3/userinfo?alt=json";
                http.open("POST", url, true);
                http.setRequestHeader("Authorization", "Bearer " + reply.AccessToken)
                http.onreadystatechange = function() {
                    if (http.readyState === 4){
                        if (http.status == 200) {
                            console.log("ok")
                            console.log("response text: " + http.responseText)
                            var response = JSON.parse(http.responseText)
                            callback(response.email)
                        } else {
                            callback("", http.responseText)
                        }
                    }
                };

                http.send("");
                return true
            }
        }

        RequestHandler {
            id: browserRequestHandler

            onRequestChanged: {
                if (request) {
                    console.log("Google RequestHandler captured request!")
                    console.log("Start URL is " + request.startUrl)
                    Qt.openUrlExternally(request.startUrl)
                } else {
                    console.log("Request destroyed!")
                }
            }
        }

        LoopbackServer {
            id: loopbackServer
            onVisited: {
                console.log("Loopback URL has been visited: " + url)
                browserRequestHandler.request.urlVisited(url)
            }
        }
    }
}
