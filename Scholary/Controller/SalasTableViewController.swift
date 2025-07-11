//
//  SalasViewControllerTableViewController.swift
//  Scholary
//
//  Created by Andre Vasques on 07/07/25.
//

import UIKit
import FirebaseFirestore

class SalasTableViewController: UITableViewController {
    
    let salaService = SalaService()
    var salas: [Sala] = []
    let alunoService = AlunoService()

    override func viewDidLoad() {
        super.viewDidLoad()

        salaService.carregarSalas { [weak self] salas in
            DispatchQueue.main.async {
                self?.salas = salas
                self?.tableView.reloadData()
            }
        }
    }

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return salas.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "SalasCell", for: indexPath)
        
        let sala = salas[indexPath.row]
        
        cell.textLabel?.text = sala.nome
        
        return cell
        
    }
    
    @IBAction func addButtonPressed(_ sender: UIBarButtonItem) {
        
        var textField = UITextField()
        
        let alert = UIAlertController(title: "Adicionar Sala", message: "Adicione uma nova sala (ex. 4ºA), para atribuir um professor e alunos.", preferredStyle: .alert)
        
        let action = UIAlertAction(title: "Adicionar", style: .default) { action in
            guard let text = textField.text?.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty else {
                return
            }
            
            let novaSala = text
            self.salaService.criarSala(sala: novaSala) { [weak self] text in
                self?.validationAlert(title: "\(text)", message: "Nova sala criada com sucesso")
            }
        }
        
        let cancel = UIAlertAction(title: "Cancelar", style: .cancel, handler: nil)
        
        alert.addTextField { (alertTextField) in
            alertTextField.placeholder = "Nome da sala"
            textField = alertTextField
        }
        
        alert.addAction(action)
        alert.addAction(cancel)
        
        present(alert, animated: true, completion: nil)
        
    }
    
    //MARK: - Delete Data from Swipe
    
    override func tableView(_ tableView: UITableView,
                            trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        let sala = self.salas[indexPath.row]
        var alunosRef: Query?
        self.alunoService.buscarAlunosDaSala(sala: sala) { alunos in
            alunosRef = alunos
        }
        
        let desvincularAction = UIContextualAction(style: .normal, title: "Desvincular") { _, _, completionHandler in
            self.confirmationAlert(title: "Desvincular todos os alunos", message: "Tem certeza que deseja desvincular todos os alunos dessa sala?", onConfirm: {
                DispatchQueue.main.async {
                    self.salaService.desvincularTodosOsAlunos(alunosRef: alunosRef!) { desvinculados in
                        self.validationAlert(title: "\(desvinculados) alunos desvinculados", message: "")
                    }
                }
                completionHandler(true)
            })
        }
        desvincularAction.backgroundColor = .orange
        
        let renomearAction = UIContextualAction(style: .normal, title: "Renomear") { _, _, completionHandler in
            let alert = UIAlertController(title: "Renomear Sala", message: "Informe o novo nome da sala.", preferredStyle: .alert)
            alert.addTextField { textField in
                textField.text = sala.nome
            }
            alert.addAction(UIAlertAction(title: "Salvar", style: .default, handler: { _ in
                let novoNome = alert.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                if !novoNome.isEmpty {
                    DispatchQueue.main.async {
                        self.salaService.renomearSala(sala: sala, novoNome: novoNome) { novoNome in
                            self.salas[indexPath.row].nome = novoNome
                            self.tableView.reloadRows(at: [indexPath], with: .automatic)
                            self.validationAlert(title: "\(novoNome)", message: "Nome da sala atualizado")
                        }
                    }
                }
            }))
            alert.addAction(UIAlertAction(title: "Cancelar", style: .cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
            completionHandler(true)
        }

        let deleteAction = UIContextualAction(style: .destructive, title: "Apagar") { _, _, completionHandler in
            self.salaService.deletarSala(alunosRef: alunosRef!, sala: sala) { desvinculados in
                DispatchQueue.main.async {
                    self.salas.remove(at: indexPath.row)
                    tableView.deleteRows(at: [indexPath], with: .automatic)
                    self.validationAlert(title: "Sala Removida", message: "\(desvinculados) alunos desvinculados da sala.")
                }
            }
            completionHandler(true)
        }

        return UISwipeActionsConfiguration(actions: [deleteAction, desvincularAction, renomearAction])
    }
    
    //MARK: - TableView Delegate Methods
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: "goToAlunos", sender: self)
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let destinationVC = segue.destination as! SalaAlunosTableViewController
        
        if let indexPath = tableView.indexPathForSelectedRow {
            destinationVC.salaSelecionada = salas[indexPath.row]
        }
    }
    
}
