/**
 * Executa a funcao ready qdo o doc. estiver pronto.
 * @param ready funcao callback a ser executada quando o documento estiver carregado.
  */
var docReady = function(ready) {
    if (document.readyState !== 'loading') return ready();
    document.addEventListener('DOMContentLoaded', ready);
    function _ready() {
        document.removeEventListener('DOMContentLoaded', ready);
        ready();
    }
}

/**
 * Executa ajax desabilitando os controles que estiverem com a classe CSS ".controle".
 *
 * @param method
 * @param url
 * @param bodyData
 * @param successCallback
 * @param errorCallback
 * @param completeCallback
 */
function ajax(method, url, bodyData, successCallback, errorCallback, completeCallback) {
    let controles = Array.from(document.getElementsByClassName("controle"));
    controles.forEach((c)=>c.disabled = true); // desabilita todos os controles durante a chamada
    var xhttp = new XMLHttpRequest();
    xhttp.onreadystatechange = function() {
        if (this.readyState === XMLHttpRequest.DONE) {
            if (this.status === 200) {
                if (successCallback) {
                    successCallback(this);
                }
            } else {
                if (errorCallback) {
                    errorCallback(this);
                }
            }
            if (completeCallback) {
                completeCallback(this);
            }
            controles.forEach((c)=>c.disabled = false); // reabilita os controles quando finaliza
        }
    };
    xhttp.open(method, url, true);
    if (bodyData) {
        xhttp.setRequestHeader("Content-type", "application/json");
        xhttp.send(JSON.stringify(bodyData));
    } else {
        xhttp.send();
    }
}

