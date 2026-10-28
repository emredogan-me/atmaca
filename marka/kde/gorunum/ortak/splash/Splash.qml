// Atmaca açılış ekranı: koyu zemin, ortada yazılı logo, altında ilerleme çubuğu.
// KSplash "stage" değerini 1'den 6'ya kadar artırır; çubuk buna göre dolar.
import QtQuick

Rectangle {
    id: kok
    color: "#0D1B2A"
    property int stage

    Image {
        anchors.fill: parent
        source: "images/zemin.jpg"
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
    }

    Column {
        anchors.centerIn: parent
        spacing: Math.round(kok.height * 0.05)
        opacity: kok.stage > 1 ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 600; easing.type: Easing.OutCubic } }

        Image {
            anchors.horizontalCenter: parent.horizontalCenter
            source: "images/logo-yazili.png"
            height: Math.round(kok.height * 0.32)
            fillMode: Image.PreserveAspectFit
            sourceSize.height: height
            smooth: true
        }

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: Math.round(kok.width * 0.16)
            height: 4
            radius: 2
            color: "#1B263B"

            Rectangle {
                width: parent.width * Math.min(kok.stage, 6) / 6
                height: parent.height
                radius: 2
                color: "#3B82F6"
                Behavior on width { NumberAnimation { duration: 500; easing.type: Easing.OutCubic } }
            }
        }
    }
}
