//
//  AlunosTableViewController.swift
//  Scholary
//
//  Created by Andre Vasques on 07/07/25.
//

import UIKit

class SalaAlunosTableViewController: UITableViewController {
    
    let alunoService = AlunoService()
    var alunos: [Aluno] = []
    var alunosSelecionados: Set<Int> = []
    
    var salaSelecionada: Sala?
    
    var indexPathParaEditar: IndexPath?
    var isInSelectionMode = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        alunoService.carregarAlunosSala(salaSelecionada: salaSelecionada) { [weak self] alunos in
            DispatchQueue.main.async {
                self?.alunos = alunos
                self?.tableView.reloadData()
            }
        }
        
        tableView.register(UINib(nibName: "AlunoTableViewCell", bundle: nil), forCellReuseIdentifier: "SalaAlunoCell")
        
        configurarBotoesPadroes()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if let sala = salaSelecionada {
            title = sala.nome
        }
    }
    
    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return alunos.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "SalaAlunoCell", for: indexPath) as? AlunoTableViewCell else {
            return UITableViewCell()
        }
        
        let aluno = alunos[indexPath.row]
        let selecionado = alunosSelecionados.contains(indexPath.row)
        
        cell.isInSelectionMode = isInSelectionMode
        cell.configurar(aluno: aluno, selecionado: selecionado)
        
        return cell
        
    }
    
    //MARK: - TableView Delegate Methods
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if alunosSelecionados.contains(indexPath.row) {
            alunosSelecionados.remove(indexPath.row)
        } else {
            alunosSelecionados.insert(indexPath.row)
        }
        
        tableView.reloadData()
        
        tableView.deselectRow(at: indexPath, animated: true)
        
    }
    
    override func tableView(_ tableView: UITableView,
                            trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        let editarAction = UIContextualAction(style: .normal, title: "Editar") { _, _, completionHandler in
            self.indexPathParaEditar = indexPath
            self.performSegue(withIdentifier: "goToEditarAlunoFromSalaAlunos", sender: self)
            completionHandler(true)
        }
        
        let removerAction = UIContextualAction(style: .destructive, title: "Remover") { _, _, completionHandler in
            let alunoASerDesvinculado = self.alunos[indexPath.row]
            self.alunoService.desvincularAlunoSala(alunoASerDesvinculado: alunoASerDesvinculado) { aluno in
                DispatchQueue.main.async {
                    tableView.reloadData()
                    self.validationAlert(title: "\(aluno.nome)", message: "Aluno removido da sala com sucesso.")
                }
            }
            completionHandler(true)
        }
        
        return UISwipeActionsConfiguration(actions: [removerAction, editarAction])
    }
    
    //MARK: - Buttons
    
    func configurarBotoesPadroes() {
        let selecionarButton = UIBarButtonItem(title: "Selecionar", style: .plain, target: self, action: #selector(didTapSelecionar))
        let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(didTapAdd))
        navigationItem.rightBarButtonItems = [addButton, selecionarButton]
    }
    
    func configurarBotoesModoSelecao() {
        let cancelarButton = UIBarButtonItem(title: "Cancelar", style: .plain, target: self, action: #selector(didTapCancelar))
        let chamadaButton = UIBarButtonItem(title: "Chamada", style: .prominent, target: self, action: #selector(didTapChamada))
        navigationItem.rightBarButtonItems = [chamadaButton, cancelarButton]
    }
    
    @objc func didTapSelecionar() {
        isInSelectionMode = true
        configurarBotoesModoSelecao()
        tableView.reloadData()
    }
    
    @objc func didTapCancelar() {
        isInSelectionMode = false
        alunosSelecionados.removeAll()
        configurarBotoesPadroes()
        tableView.reloadData()
    }
    
    @objc func didTapAdd() {
        performSegue(withIdentifier: "adicionarAlunos", sender: self)
    }
    
    @objc func didTapChamada() {
        alunoService.realizarChamada(
            salaSelecionada: salaSelecionada,
            alunosSelecionados: alunosSelecionados,
            alunosArray: alunos
        ) { alunos in
            self.validationAlert(title: "Chamada realizada", message: "Foram registradas \(alunos.count) presenças dentre os \(self.alunos.count) alunos.")
            self.isInSelectionMode = false
            self.alunosSelecionados.removeAll()
            self.configurarBotoesPadroes()
            self.tableView.reloadData()
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "adicionarAlunos" {
            if let destination = segue.destination as? VincularAlunosTableViewController, let sala = salaSelecionada {
                destination.salaSelecionada = sala
            }
        } else if segue.identifier == "goToEditarAlunoFromSalaAlunos" {
            if let destination = segue.destination as? EditarAlunoViewController {
                let indexPath = indexPathParaEditar ?? tableView.indexPathForSelectedRow
                if let indexPath = indexPath {
                    destination.aluno = alunos[indexPath.row]
                    indexPathParaEditar = nil
                }
            }
        }
    }
    
}
