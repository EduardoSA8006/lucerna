pragma Singleton

import Quickshell
import qs.services.lucerna

// A conexão permanente do shell com o lucernad (o daemon do sistema), aberta
// enquanto o shell roda: cada módulo (services/SystemStats.qml e os próximos)
// escolhe os tópicos dele por `client` e lê os estados em `client.states`.
// A espera entre tentativas vai até 30 s: sem o lucernad instalado, o Socket do
// Quickshell escreve um WARN por tentativa, e o teto de 5 s encheria o log.
Singleton {
    readonly property LucernaClient client: LucernaClient {
        app: "lucernad"
        maxBackoff: 30000
    }
}
