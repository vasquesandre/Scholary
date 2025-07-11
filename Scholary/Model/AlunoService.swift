//
//  AlunoService.swift
//  Scholary
//
//  Created by Andre Vasques on 11/07/25.
//

import FirebaseFirestore

class AlunoService {
    
    private let db = Firestore.firestore()
    
    func carregarAlunosSala(salaSelecionada: Sala?, completion: @escaping ([Aluno]) -> Void) {
        guard let sala = salaSelecionada else {
            completion([])
            return
        }
        
        db.collection("alunos")
            .whereField("sala", isEqualTo: sala.id)
            .order(by: "nome")
            .addSnapshotListener { (snapshot, error) in
                var alunos: [Aluno] = []
                if let snapshotDocuments = snapshot?.documents {
                    for doc in snapshotDocuments {
                        let data = doc.data()
                        if let nome = data["nome"] as? String, let salaId = data["sala"] as? String {
                            let aluno = Aluno(id: doc.documentID, nome: nome, salaId: salaId, salaNome: nil)
                            alunos.append(aluno)
                        }
                    }
                }
                completion(alunos)
            }
    }
    
    func carregarTodosOsAlunos(completion: @escaping ([Aluno]) -> Void) {
        db.collection("alunos")
            .order(by: "nome")
            .addSnapshotListener { (snapshot, error) in
            if let e = error {
                print("Error retrieving data form Firestore -> \(e)")
            } else {
                var alunos: [Aluno] = []
                if let snapshotDocuments = snapshot?.documents {
                    for doc in snapshotDocuments {
                        let data = doc.data()
                        let alunoID = doc.documentID
                        let nome = data["nome"] as? String ?? ""
                        let salaId = data["sala"] as? String
                        if let salaId = salaId, !salaId.isEmpty {
                            self.db.collection("salas").document(salaId).getDocument { (salaSnapshot, error) in
                                let salaNome = salaSnapshot?.data()?["nome"] as? String
                                let aluno = Aluno(id: alunoID, nome: nome, salaId: salaId, salaNome: salaNome)
                                alunos.append(aluno)
                            }
                        } else {
                            let aluno = Aluno(id: alunoID, nome: nome, salaId: nil, salaNome: nil)
                            alunos.append(aluno)
                        }
                    }
                }
                completion(alunos)
            }
        }
    }
    
    func vincularAlunosSala(salaSelecionada sala: Sala?, alunosParaVincular: Set<Int>, alunosArray alunos: [Aluno], completion: @escaping ([Aluno]) -> Void) {
        guard let sala = sala else {
            completion([])
            return
        }
        
        let alunosParaVincular = alunosParaVincular.map { alunos[$0] }
        for aluno in alunosParaVincular {
            db.collection("alunos").document(aluno.id).updateData(["sala": sala.id]) { error in
                if let error = error {
                    print("Erro ao vincular sala para aluno \(aluno.nome): \(error)")
                }
            }
        }
        completion(alunosParaVincular)
    }
    
    func desvincularAlunoSala(alunoASerDesvinculado aluno: Aluno, completion: @escaping (Aluno) -> Void) {
        let alunoRef = self.db.collection("alunos").document(aluno.id)
        alunoRef.updateData(["sala": ""]) { error in
            if let error = error {
                print("Erro ao desvincular aluno: \(error.localizedDescription)")
            } else {
                completion(aluno)
            }
        }
    }
    
    func buscarAlunosDaSala(sala: Sala, completion: @escaping (Query) -> Void) {
        var alunos = db.collection("alunos").whereField("sala", isEqualTo: sala.id)
        completion(alunos)
    }
}
