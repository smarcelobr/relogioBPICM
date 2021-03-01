let getStatusSuccessCallback = function (httpRequest) {
    let status = JSON.parse(httpRequest.responseText);
    // RTC
    document.getElementById("rtc_time").innerText = status.rtc.time;
    document.getElementById("rtc_difTimezone").innerText = status.rtc.difTimezone;
    // PTR
    document.getElementById("ptr_time").innerText = status.ptr.time;
    document.getElementById("ptr_difMinutos").innerText = status.ptr.difMinutos;
    document.getElementById("gravarDifMinutosBtn").style.display = status.ptr.savePendent ? "block" : "none";
    // falhaMotor
    document.getElementById("status_falhaMotor").style.display = status.falhaMotor ? "block" : "none";
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

docReady(function () {
    consultaNome();
    setInterval(consultaStatus, 20000); // atualiza status da tela cada 20 segundos
});
