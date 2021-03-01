let getConfigSuccessCallback = function (httpRequest) {
    let cfg = JSON.parse(httpRequest.responseText);
    if (cfg.nome) {
        document.getElementById("inputNome").value = cfg.nome;
    }
    // Wifi
    document.getElementById("cfg_wifi_sta_ssid").innerText = cfg.wifi.sta.ssid;
    document.getElementById("cfg_wifi_sta_pwd").innerText = cfg.wifi.sta.pwd;

    // Horario de Verao
    let tbodyHoraVerao = document.getElementById("tbody_hora_verao");
    // remove todas as linhas pre-existentes:
    removeChildren(tbodyHoraVerao);
    // inclui as linhas da configuracao:
    cfg.rtc.dif.forEach(function (rtcDif) {
            let linhaHoraVerao = document.createElement("tr");
            let celulaHora = document.createElement("td");
            let celulaDif = document.createElement("td");
            celulaHora.innerText = new Date(rtcDif.epoch * 1000).toLocaleString('pt-BR')
            celulaDif.innerText = rtcDif.dif + " minutos";
            linhaHoraVerao.append(celulaHora);
            linhaHoraVerao.append(celulaDif)
            tbodyHoraVerao.append(linhaHoraVerao);
        }
    )
};

function consultaConfig() {
    ajax("GET", "config.json", null, getConfigSuccessCallback);
}

let getNomeSuccessCallback = function (httpRequest) {
    let resposta = JSON.parse(httpRequest.responseText);
    if (resposta.nome) {
        document.getElementById("inputNome").innerText = resposta.nome;
    }
}

function salvarNomeBtn() {
    let novoNome = document.getElementById("inputNome").value;
    ajax("POST", "nome", {nome: novoNome}, getNomeSuccessCallback, null, null);
}

function editarWifiStationConfigBtn() {
    document.getElementById("cfg_wifi").style.display = "none";
    document.getElementById("cfg_wifi_edit").style.display = "block";
    document.getElementById("inputWifiPass").value = document.getElementById("cfg_wifi_sta_pwd").innerText;
    let ssidAtual = document.getElementById("cfg_wifi_sta_ssid").innerText;
    let selectWifiSSID = document.getElementById("select_cfg_wifi_sta_ssid");
    removeChildren(selectWifiSSID);
    ajax("GET", "wifiAPs", null, function (httpRequest) {
        let ssidArray = JSON.parse(httpRequest.responseText);
        ssidArray.forEach(function(ssidName, idx) {
            let optionSSID = document.createElement("option");
            optionSSID.value=idx;
            optionSSID.text=ssidName;
            optionSSID.selected = (ssidName===ssidAtual);
            selectWifiSSID.append(optionSSID);
        });
    });
}

function salvarWifiStationConfigBtn() {
    let selectWifiSSID = document.getElementById("select_cfg_wifi_sta_ssid");

    ajax("POST", "setwifi",
        {ssid: selectWifiSSID.options[selectWifiSSID.selectedIndex].text,
                   pwd: document.getElementById("inputWifiPass").value},
        function(httpRequest) {
            let wifi = JSON.parse(httpRequest.responseText);
            document.getElementById("cfg_wifi").style.display = "block";
            document.getElementById("cfg_wifi_edit").style.display = "none";
            document.getElementById("cfg_wifi_sta_ssid").innerText = wifi.ssid;
            document.getElementById("cfg_wifi_sta_pwd").innerText = wifi.pwd;
        });
}

docReady(function () {
    consultaConfig();
});
