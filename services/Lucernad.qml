pragma Singleton

import Quickshell
import qs.services.lucerna

// A conexão permanente do shell com o lucernad (o daemon do sistema), aberta
// enquanto o shell roda: cada módulo (services/SystemStats.qml e os próximos)
// escolhe os tópicos dele por `client` e lê os estados em `client.states`.
Singleton {
    readonly property LucernaClient client: LucernaClient {
        app: "lucernad"
    }
}
