
let successCallback = function (httpRequest) {
    let status = JSON.parse(httpRequest.responseText);
    // RTC
    document.getElementById("rtc_time").innerText = status.rtc.time;
    document.getElementById("rtc_difTimezone").innerText = status.rtc.difTimezone;
    // PTR
    document.getElementById("ptr_time").innerText = status.ptr.time;
    // falhaMotor
    document.getElementById("status_falhaMotor").style.display = status.falhaMotor?"block":"none";
};

function consultaStatus() {
    ajax("GET", "status", null, successCallback);
}

function incrementa(minutos) {
    ajax("POST", "inc", {min: minutos}, successCallback, null, null);
}

function limparFlagMotor(minutos) {
    ajax("POST", "lfm", null, successCallback, null, null);
}

function gravarDifMinutos() {
    ajax("POST", "gdf", null, successCallback, null, null);
}
docReady(function () {
    consultaStatus();
    setInterval(consultaStatus, 20000); // atualiza status da tela cada 20 segundos
});
