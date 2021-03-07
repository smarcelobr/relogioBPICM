let getStatusSuccessCallback = function (httpRequest) {
    let status = JSON.parse(httpRequest.responseText);
    // RTC
    document.getElementById("rtc_time").innerText = status.rtc.time;
    document.getElementById("rtc_difTimezone").innerText = status.rtc.difTimezone;
    document.getElementById("browser_time").innerText = (new Date()).toLocaleString();
    // PTR
    document.getElementById("ptr_time").innerText = status.ptr.time;
    document.getElementById("ptr_difMinutos").innerText = status.ptr.difMinutos;
    document.getElementById("gravarDifMinutosBtn").style.display = status.ptr.savePendent ? "block" : "none";
    // falhaMotor
    document.getElementById("status_falhaMotor").style.display = status.falhaMotor ? "block" : "none";
    document.getElementById("avisoPausado").style.display = status.pausado ? "block" : "none";
    document.getElementById("pausarBtn").style.display = !status.pausado ? "block" : "none";
    document.getElementById("continuarBtn").style.display = status.pausado ? "block" : "none";
};

function consultaStatus() {
    ajax("GET", "status", null, getStatusSuccessCallback);
}

let getNomeSuccessCallback = function (httpRequest) {
    let resposta = JSON.parse(httpRequest.responseText);
    if (resposta.nome) {
        document.getElementById("cfg_nome").innerText = resposta.nome;
    }
    consultaStatus();
}

function consultaNome() {
    ajax("GET", "nome", null, getNomeSuccessCallback);
}

function incrementa(minutos) {
    ajax("POST", "inc", {min: minutos}, getStatusSuccessCallback, null, null);
}

function limparFlagMotor(minutos) {
    ajax("POST", "lfm", null, getStatusSuccessCallback, null, null);
}

function gravarDifMinutos() {
    ajax("POST", "gdm", null, getStatusSuccessCallback, null, null);
}

function setTimeDoBrowser() {
    let unixEpoch = Math.floor((new Date()).getTime()/1000);
    ajax("POST", "time", {epoch: unixEpoch}, getStatusSuccessCallback, null, null);
}

function pausar() {
    ajax("POST", "pausar", null, getStatusSuccessCallback, null, null);
}

function continuar() {
    ajax("POST", "continuar", null, getStatusSuccessCallback, null, null);
}

docReady(function () {
    consultaNome();
    setInterval(consultaStatus, 20000); // atualiza status da tela cada 20 segundos
});
