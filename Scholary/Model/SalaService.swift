//
//  SalaService.swift
//  Scholary
//
//  Created by Andre Vasques on 11/07/25.
//

import FirebaseFirestore

class SalaService {
    
    private let db = Firestore.firestore()
    
    func criarSala(sala text: String, completion: @escaping (String) -> Void) {
        db.collection("salas").addDocument(data: [
            "nome": text
        ]) { (error) in
            if let e = error {
                print("Issue saving to firestore, \(e)")
            } else {
                completion(text)
            }
        }
    }
    
    func carregarSalas(completion: @escaping ([Sala]) -> Void) {
        db.collection("salas")
            .order(by: "nome")
            .addSnapshotListener { (snapshot, error) in
            if let e = error {
                print("Error retrieving data form Firestore -> \(e)")
            } else {
                var salas: [Sala] = []
                if let snapshotDocuments = snapshot?.documents {
                    for doc in snapshotDocuments {
                        let data = doc.data()
                        if let nome = data["nome"] as? String {
                            let sala = Sala(id: doc.documentID, nome: nome)
                            salas.append(sala)
                        }
                    }
                }
                completion(salas)
            }
        }
    }
    
    func renomearSala(sala: Sala, novoNome: String, completion: @escaping (String) -> Void) {
        self.db.collection("salas").document(sala.id).updateData(["nome": novoNome]) { err in
            if let err = err {
                print("Erro ao renomear sala: \(err.localizedDescription)")
            } else {
                completion(novoNome)
            }
        }
    }
    
    func desvincularTodosOsAlunos(alunosRef: Query, completion: @escaping (Int) -> Void) {
        alunosRef.getDocuments { (snapshot, error) in
            if let error = error {
                print("Erro ao buscar alunos: \(error.localizedDescription)")
            } else {
                let documentos = snapshot?.documents ?? []
                var desvinculados = 0
                let dispatchGroup = DispatchGroup()
                for doc in documentos {
                    dispatchGroup.enter()
                    let alunoRef = self.db.collection("alunos").document(doc.documentID)
                    alunoRef.updateData(["sala": ""]) { err in
                        if err == nil {
                            desvinculados += 1
                        }
                        dispatchGroup.leave()
                    }
                }
                dispatchGroup.notify(queue: .main) {
                    completion(desvinculados)
                }
            }
        }
    }
    
    func deletarSala(alunosRef: Query, sala: Sala, completion: @escaping (Int) -> Void) {
        alunosRef.getDocuments { (snapshot, error) in
            if let error = error {
                print("Erro ao buscar alunos: \(error.localizedDescription)")
                return
            }
            let documentos = snapshot?.documents ?? []
            var desvinculados = 0
            let dispatchGroup = DispatchGroup()
            for doc in documentos {
                dispatchGroup.enter()
                let alunoRef = self.db.collection("alunos").document(doc.documentID)
                alunoRef.updateData(["sala": ""]) { err in
                    if err == nil {
                        desvinculados += 1
                    }
                    dispatchGroup.leave()
                }
            }
            dispatchGroup.notify(queue: .main) {
                self.db.collection("salas").document(sala.id).delete { err in
                    if let err = err {
                        print("Erro ao remover sala: \(err.localizedDescription)")
                    } else {
                        completion(desvinculados)
                    }
                }
            }
        }
    }
    
    
}
