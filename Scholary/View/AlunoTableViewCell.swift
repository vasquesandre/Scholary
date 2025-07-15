//
//  AlunoTableViewCell.swift
//  Scholary
//
//  Created by Andre Vasques on 14/07/25.
//

import UIKit

class AlunoTableViewCell: UITableViewCell {
    
    @IBOutlet weak var selectionImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var leadingConstraint: NSLayoutConstraint!
    
    var isInSelectionMode: Bool = false {
        didSet {
            
            UIView.animate(withDuration: 0.3, animations: {
                self.leadingConstraint.constant = self.isInSelectionMode ? 30 : 0
                self.selectionImageView.alpha = self.isInSelectionMode ? 1 : 0
                self.layoutIfNeeded()
            })
        }
    }
    
    func configurar(aluno: Aluno, selecionado: Bool) {
        nameLabel.text = aluno.nome
        selectionImageView.image = selecionado ?
        UIImage(systemName: "checkmark.circle.fill") :
        UIImage(systemName: "circle")
    }
    
}
