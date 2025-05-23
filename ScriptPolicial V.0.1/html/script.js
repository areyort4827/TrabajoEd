function openTab(tab) {
    document.getElementById("content").innerHTML = `<p>Cargando módulo: ${tab}...</p>`;
    fetch(`https://${GetParentResourceName()}/loadModule`, {
        method: 'POST',
        headers: {'Content-Type': 'application/json'},
        body: JSON.stringify({ module: tab })
    });
}

function closeUI() {
    fetch(`https://${GetParentResourceName()}/closeUI`, {
        method: 'POST'
    });
}

window.addEventListener("message", function(event) {
    if (event.data.action === "openUI") {
        document.getElementById("main").style.display = "block";
    } else if (event.data.action === "closeUI") {
        document.getElementById("main").style.display = "none";
    }
});
